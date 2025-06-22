import SwiftUI

struct GroupDiningCard: View {
    let groupDining: GroupDining
    @ObservedObject var viewModel: GroupDiningViewModel
    let showJoinButton: Bool
    @State private var showingParticipants = false
    @State private var showingInviteFriends = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with restaurant info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupDining.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text(groupDining.restaurantName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicator
                statusBadge
            }
            
            // Description
            if !groupDining.description.isEmpty {
                Text(groupDining.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text(groupDining.scheduledDate, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                    .padding(.leading, 8)
                
                Text(groupDining.scheduledDate, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Participants info
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text("\(groupDining.currentParticipants.count)/\(groupDining.maxParticipants) participants")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("View Participants") {
                    showingParticipants = true
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
            
            // Progress bar
            ProgressView(value: Double(groupDining.currentParticipants.count), total: Double(groupDining.maxParticipants))
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                .scaleEffect(y: 2)
            
            // Action buttons
            HStack(spacing: 12) {
                if showJoinButton && viewModel.canJoinGroupDining(groupDining) {
                    Button(action: {
                        viewModel.joinGroupDining(groupDining) { success in
                            // Handle result
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Join Group")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(20)
                    }
                } else if !showJoinButton && viewModel.canLeaveGroupDining(groupDining) {
                    Button(action: {
                        viewModel.leaveGroupDining(groupDining) { success in
                            // Handle result
                        }
                    }) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                            Text("Leave Group")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
                
                // Invite friends button (for group members)
                if !showJoinButton {
                    Button(action: {
                        showingInviteFriends = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Invite")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .sheet(isPresented: $showingParticipants) {
            GroupDiningParticipantsView(groupDining: groupDining)
        }
        .sheet(isPresented: $showingInviteFriends) {
            InviteFriendsToGroupView(groupDining: groupDining, viewModel: viewModel)
        }
    }
    
    private var statusBadge: some View {
        Group {
            switch groupDining.status {
            case .active:
                if groupDining.isExpired {
                    Label("Expired", systemImage: "clock.badge.xmark")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else if groupDining.isFull {
                    Label("Full", systemImage: "person.fill.checkmark")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Label("Open", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            case .cancelled:
                Label("Cancelled", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            case .completed:
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

struct GroupDiningInvitationCard: View {
    let invitation: GroupDiningInvitation
    @ObservedObject var viewModel: GroupDiningViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.groupTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Invited by \(invitation.fromUserName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Label("New", systemImage: "envelope.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Restaurant and date info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(invitation.restaurantName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(invitation.scheduledDate, style: .date)
                        .font(.subheadline)
                    
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                        .padding(.leading, 8)
                    Text(invitation.scheduledDate, style: .time)
                        .font(.subheadline)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.respondToInvitation(invitation, response: .accepted) { success in
                        // Handle result
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Accept")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(20)
                }
                
                Button(action: {
                    viewModel.respondToInvitation(invitation, response: .declined) { success in
                        // Handle result
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Decline")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
        )
    }
}
