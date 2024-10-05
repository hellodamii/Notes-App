//
//  Home.swift
//  Notes App
//
//  Created by Damilare on 02/10/2024.
//

import SwiftUI
import SwiftData

struct Home: View {
    @State private var searchText: String = ""
    @State private var selectedNote: Note?
    @State private var deleteNote: Note?
    @State private var animateView: Bool = false
    @FocusState private var isKeyboardActive: Bool
    @Namespace private var animation
    @Query(sort: [.init(\Note.dateCreated, order: .reverse)], animation: .snappy)
    private var notes: [Note]
    @Environment(\.modelContext) private var context
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
               SearchBar()
                
                LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                    ForEach(notes) { note in
                        CardView(note)
                            .frame(height: 160)
                            .onTapGesture {
                                guard selectedNote == nil else { return }
                                
                                selectedNote = note
                                note.allowsHitTesting = true
                                withAnimation(noteAnimation) {
                                    animateView = true
                                }
                            }
                    }
                }
            }
        }
        .safeAreaPadding(15)
        .overlay {
            GeometryReader {
                let size = $0.size
                ForEach(notes) {note in
                    if note.id == selectedNote?.id && animateView {
                        DetailView(size: size, animation: animation, note: note)
                            .ignoresSafeArea(.container, edges: .top)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomBar()
        }
        .focused($isKeyboardActive)
    }
    
    // Search Bar
    @ViewBuilder
    func SearchBar() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
            
            TextField("Search", text: $searchText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    func CardView(_ note: Note) -> some View {
        ZStack {
            if selectedNote?.id == note.id && animateView {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.clear)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(note.color.gradient)
                    .matchedGeometryEffect(id: note.id, in: animation)
            }
        }
    }
    
    @ViewBuilder
    func BottomBar() -> some View {
        HStack(spacing: 15) {
            Group {
                if !isKeyboardActive {
                    Button {
                        if selectedNote == nil {
                            createEmptyNote()
                        } else {
                            selectedNote?.allowsHitTesting = false
                            deleteNote = selectedNote
                            withAnimation(noteAnimation.logicallyComplete(after: 0.1), completionCriteria: .logicallyComplete) {
                                selectedNote = nil
                                animateView = false
                            } completion: {
                                deleteNoteFromContext()
                            }
                        }
                    } label: {
                        Image(systemName: selectedNote == nil ? "plus.circle.fill" : "trash.fill")
                            .font(.title2)
                            .foregroundStyle( selectedNote == nil ? Color.primary : .red)
                            .contentShape(.rect)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
            
            
            Spacer(minLength: 0)
            
            ZStack {
                if isKeyboardActive {
                    Button("Save") {
                        isKeyboardActive = false
                    }
                    .font(.title3)
                    .foregroundStyle(Color.primary)
                    .transition(.blurReplace)
                }
                if selectedNote != nil && !isKeyboardActive{
                    Button {
                        selectedNote?.allowsHitTesting = false
                        
                        if let firstIndex = notes.firstIndex(where: { $0.id ==
                            selectedNote?.id}) {
                            notes[firstIndex].allowsHitTesting = false
                        }
                        
                        if let selectedNote, (selectedNote.title.isEmpty && selectedNote.content.isEmpty) {
                            deleteNote = selectedNote
                        }
                        
                        withAnimation(noteAnimation.logicallyComplete(after: 0.1), completionCriteria: .logicallyComplete) {
                            animateView = false
                            selectedNote = nil
                        } completion: {
                            deleteNoteFromContext()
                        }
                    } label: {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.title3)
                            .foregroundStyle(Color.primary)
                            .contentShape(.rect)
                    }
                    .transition(.blurReplace)
                }
            }
           
        }
        .overlay {
            Text("Notes")
                .font(.callout)
                .fontWeight(.semibold)
                .opacity(selectedNote != nil ? 0 : 1)
        }
        .overlay {
            if selectedNote != nil {
                CardColorPicker()
                    .transition(.blurReplace)
            }
        }
        .padding(15)
        .background(.bar)
        .animation(noteAnimation, value: selectedNote != nil)
    }
    @ViewBuilder
    func CardColorPicker() -> some View {
        HStack(spacing: 20) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(Color("Note \(index)"))
                    .frame(width: 20, height: 20)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(noteAnimation) {
                            selectedNote?.colorString = "Note \(index)"
                        }
                    }
            }
        }
    }
    
    func createEmptyNote() {
        let colors: [String] = (1...6).compactMap({ "Note \($0)" })
        let randomColor = colors.randomElement()!
        let note = Note(colorString: randomColor, title: "", content: "")
        
        context.insert(note)
        
        Task {
            try? await Task.sleep(for: .seconds(0))
            selectedNote = note
            selectedNote?.allowsHitTesting = true
            
            withAnimation(noteAnimation) {
                animateView = true
            }
        }
    }
    
    func deleteNoteFromContext() {
        if let deleteNote {
            context.delete(deleteNote)
            try? context.save()
            self.deleteNote = nil
        }
    }
}
struct DetailView: View {
    var size: CGSize
    var animation: Namespace.ID
   @Bindable var note: Note
    /// View properties
    @State private var animateLayers: Bool = false
    var body: some View {
        Rectangle()
            .fill(note.color.gradient)
            .overlay {
                NotesContent()
            }
            .clipShape(.rect(cornerRadius: animateLayers ? 0 : 10))
            .matchedGeometryEffect(id: note.id, in: animation)
            .transition(.offset(y: 1))
            .allowsHitTesting(note.allowsHitTesting)
            .onChange(of: note.allowsHitTesting, initial: true) { oldValue, newValue in
                withAnimation(noteAnimation) {
                    animateLayers = newValue
                }
            }
        }
    
    @ViewBuilder
    func NotesContent() -> some View {
        GeometryReader {
            let currentSize: CGSize = $0.size
            
            
            VStack(alignment: .leading, spacing: 15) {
                TextField("Title", text: $note.title, axis: .vertical)
                    .font(.title2)
                    .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                
                TextEditor(text: $note.content)
                    .font(.title3)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if note.content.isEmpty {
                            Text("Add a note...")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .offset(x: 8, y: 8)
                        }
                    }
            }
            .tint(.black)
            .padding(15)
            .padding(.top, safeArea.top)
            .frame(width: size.width, height: size.height)
            .frame(width: currentSize.width, height: currentSize.height, alignment: .topLeading)
        }
        .blur(radius: animateLayers ? 0 : 100)
        .opacity(animateLayers ? 1 : 0)
    }
    var safeArea: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first 
                           as? UIWindowScene)?.keyWindow?.safeAreaInsets {
            return safeArea
        }
        
        return.zero
    }
    }

extension View {
    var noteAnimation: Animation {
        .smooth(duration: 0.3, extraBounce: 0)
    }
}

#Preview {
    ContentView()
}
