
//  Messages .swift
//  MedTeamApp
//
//  Created by Robert Plummer on 9/27/24.

//struct MessageView: View {
//    @StateObject var sessionVM = SessionViewModel()
//    @State var chatMessages: [ChatMessage] = ChatMessage.sampleMessages
//    @State var messageText: String = ""
//    @State var selectedSession: Session?
//    @State var showMenu: Bool = false
//    @State var buttonPosition: CGPoint = .zero
//    let selectedHospital: Hospital
//    let selectedServices: [String]
//
//    var body: some View {
//        ZStack {
//            if showMenu {
//                Hamburger(showHamburger: $showMenu)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .background(Color.black.opacity(0.75))
//                    .edgesIgnoringSafeArea(.all)
//            }
//
//            VStack {
//                GeometryReader { proxy in
//                    ScrollView {
//                        ScrollViewReader { scrollView in
//                            LazyVStack {
//                                ForEach(chatMessages, id: \.id) { message in
//                                    messageView(message: message)
//                                        .id(message.id)
//                                        .background(GeometryReader { geometry in
//                                            Color.clear
//                                            .onAppear {
//                                                if message.id == chatMessages.first?.id {
//                                                    buttonPosition = geometry.frame(in: .global).origin
//                                                }
//                                            }
//                                        })
//                                }
//                            }
//                            .onAppear {
//                                withAnimation {
//                                    scrollView.scrollTo(chatMessages.last?.id, anchor: .bottom)
//                                }
//                            }
//                        }
//                    }
//                    .padding(.top, buttonPosition.y)
//                }
//
//                HStack {
//                    TextField("Type your message", text: $messageText)
//                        .padding()
//                        .background(.gray.opacity(0.1))
//                        .cornerRadius(12)
//                    Button(action: sendMessage) {
//                        Text("Send")
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(.black)
//                            .cornerRadius(12)
//                    }
//                }
//                .padding()
//
//                // Session View Container
//                ScrollView(.horizontal, showsIndicators: false) {
//                    LazyHStack {
//                        ForEach(Array(sessionVM.sessions.enumerated()), id: \.1.id) { index, session in
//                            let user = sessionVM.users[session.userID]
//                            SessionDataRow(session: session, isMySession: index == 0, user: user)
//                                .frame(width: 250)
//                                .padding(.trailing, 10)
//                        }
//                    }
//                }
//                .padding(.horizontal)
//            }
//            .padding()
//            .offset(x: showMenu ? 330 : 0, y: 12)
//            .disabled(showMenu)
//
//
//            Button(action: { showMenu.toggle() }) {
//                Image(systemName: "line.horizontal.3")
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(.black)
//                    .cornerRadius(12)
//            }
//            .position(x: buttonPosition.x + 20, y: buttonPosition.y - 30)
//        }
//        .onAppear {
//            sessionVM.fetchSessions(forHospital: selectedHospital, selectedServices: selectedServices)
//        }
//    }
//
//
//    func messageView(message: ChatMessage) -> some View {
//        HStack {
//            if message.sender == .me { Spacer() }
//            Text(message.content)
//                .foregroundColor(message.sender == .me ? .white : .black)
//                .padding()
//                .background(message.sender == .me ? .blue : .gray.opacity(0.1))
//                .cornerRadius(16)
//            if message.sender == .other { Spacer() }
//        }
//    }
//
//
//    func sendMessage() {
//        let newMessage = ChatMessage(id: UUID().uuidString, content: messageText, dataCreated: Date(), sender: .me)
//        chatMessages.append(newMessage)
//        messageText = ""
//    }
//}
