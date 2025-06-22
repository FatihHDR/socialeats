import SwiftUI

struct GroupDiningView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel: GroupDiningViewModel
    @State private var selectedTab: GroupDiningTab = .discover
    @State private var showingCreateGroup = false
    @State private var showingInvitations = false
    
    init() {
        _viewModel = StateObject(wrappedValue: GroupDiningViewModel(authService: AuthenticationService()))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Selector
                Picker("Tab", selection: $selectedTab) {
                    Text("Discover").tag(GroupDiningTab.discover)
                    Text("My Groups").tag(GroupDiningTab.myGroups)
                    Text("Invitations (\(viewModel.invitations.count))").tag(GroupDiningTab.invitations)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case .discover:
                    DiscoverGroupDiningView(viewModel: viewModel)
                case .myGroups:
                    MyGroupDiningView(viewModel: viewModel)
                case .invitations:
                    GroupDiningInvitationsView(viewModel: viewModel)
                }
                
                Spacer()
            }
            .navigationTitle("Group Dining")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                viewModel.loadGroupDinings()
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupDiningView { success in
                    if success {
                        viewModel.loadGroupDinings()
                    }
                }
                .environmentObject(authService)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showGroupDining)) { _ in
            selectedTab = .invitations
        }
    }
}

enum GroupDiningTab: CaseIterable {
    case discover
    case myGroups
    case invitations
}

struct DiscoverGroupDiningView: View {
    @ObservedObject var viewModel: GroupDiningViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading groups...")
                        .padding()
                } else if viewModel.groupDinings.isEmpty {
                    EmptyGroupDiningView()
                } else {
                    ForEach(viewModel.groupDinings) { groupDining in
                        GroupDiningCard(
                            groupDining: groupDining,
                            viewModel: viewModel,
                            showJoinButton: true
                        )
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.loadGroupDinings()
        }
    }
}

struct MyGroupDiningView: View {
    @ObservedObject var viewModel: GroupDiningViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading your groups...")
                        .padding()
                } else if viewModel.userGroupDinings.isEmpty {
                    EmptyMyGroupsView()
                } else {
                    ForEach(viewModel.userGroupDinings) { groupDining in
                        GroupDiningCard(
                            groupDining: groupDining,
                            viewModel: viewModel,
                            showJoinButton: false
                        )
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.loadGroupDinings()
        }
    }
}

struct GroupDiningInvitationsView: View {
    @ObservedObject var viewModel: GroupDiningViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading invitations...")
                        .padding()
                } else if viewModel.invitations.isEmpty {
                    EmptyInvitationsView()
                } else {
                    ForEach(viewModel.invitations) { invitation in
                        GroupDiningInvitationCard(
                            invitation: invitation,
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.loadGroupDinings()
        }
    }
}

struct EmptyGroupDiningView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Group Dining Events")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Start a group dining event and invite your friends to join you for a meal!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 40)
    }
}

struct EmptyMyGroupsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Group Events Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Create your first group dining event or join others to get started!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 40)
    }
}

struct EmptyInvitationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Invitations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("When friends invite you to group dining events, they'll appear here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    GroupDiningView()
        .environmentObject(AuthenticationService())
}
