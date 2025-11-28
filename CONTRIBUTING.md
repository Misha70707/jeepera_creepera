# Contributing to CodeForge AI

Thank you for your interest in contributing to CodeForge AI! This document provides guidelines and best practices for contributing.

## Table of Contents
1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Pull Request Process](#pull-request-process)
7. [Issue Guidelines](#issue-guidelines)

## Code of Conduct

### Our Pledge
We are committed to providing a welcoming and inclusive environment for all contributors, regardless of experience level, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, religion, or nationality.

### Expected Behavior
- Be respectful and considerate
- Use welcoming and inclusive language
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior
- Harassment, trolling, or discriminatory comments
- Publishing others' private information
- Inappropriate sexual attention or advances
- Other conduct which could reasonably be considered unprofessional

**Enforcement**: Violations should be reported to conduct@codeforgeai.app. All reports will be reviewed and investigated.

## Getting Started

### Prerequisites
Before contributing, ensure you have:
1. Read the [README.md](README.md)
2. Followed the [Development Setup Guide](docs/guides/DEVELOPMENT_SETUP.md)
3. Reviewed the [Architecture Overview](docs/architecture/OVERVIEW.md)
4. Joined our [Discord community](https://discord.gg/codeforgeai) (optional but recommended)

### Finding an Issue to Work On

**Good First Issues**
Look for issues tagged with `good first issue` - these are designed for newcomers.

**Help Wanted**
Issues tagged `help wanted` are ready for contribution and have clear requirements.

**Feature Requests**
Check issues tagged `feature request` for new functionality to implement.

**Bugs**
Issues tagged `bug` need investigation and fixes.

### Claiming an Issue
1. Comment on the issue: "I'd like to work on this"
2. Wait for maintainer approval (usually within 24 hours)
3. If approved, the issue will be assigned to you
4. If no response within 7 days, the issue becomes available again

## Development Workflow

### 1. Fork the Repository
```bash
# Click "Fork" on GitHub, then clone your fork:
git clone https://github.com/YOUR_USERNAME/tweny_fo_seven_tree_sixty_five.git
cd tweny_fo_seven_tree_sixty_five
```

### 2. Add Upstream Remote
```bash
git remote add upstream https://github.com/Misha70707/tweny_fo_seven_tree_sixty_five.git
```

### 3. Create a Feature Branch
```bash
# Always branch from main
git checkout main
git pull upstream main

# Create feature branch (use descriptive names)
git checkout -b feature/add-voice-mode
# or
git checkout -b fix/chat-crash-on-long-messages
# or
git checkout -b docs/improve-setup-guide
```

**Branch Naming Convention**:
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring
- `test/description` - Test additions/improvements
- `chore/description` - Maintenance tasks

### 4. Make Your Changes
- Write clean, readable code
- Follow coding standards (see below)
- Add tests for new functionality
- Update documentation as needed

### 5. Commit Your Changes
```bash
git add .
git commit -m "feat: Add voice-to-code mode

- Implement speech-to-text using native APIs
- Add voice input button to chat interface
- Add voice settings to preferences
- Update documentation

Closes #42"
```

**Commit Message Format**:
```
<type>: <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `style`: Code style changes (formatting)

**Example**:
```
fix: Resolve crash when sending empty message

The app crashed when users tapped send without typing anything.
Added validation to check for empty messages before sending.

Fixes #123
```

### 6. Keep Your Branch Updated
```bash
git fetch upstream
git rebase upstream/main
```

If conflicts occur, resolve them and continue:
```bash
# Fix conflicts in your editor
git add .
git rebase --continue
```

### 7. Push to Your Fork
```bash
git push origin feature/add-voice-mode
```

### 8. Create a Pull Request
1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill out the PR template (see below)
4. Submit the PR

## Coding Standards

### General Principles
1. **DRY** (Don't Repeat Yourself) - Extract common code into reusable functions/classes
2. **KISS** (Keep It Simple, Stupid) - Prefer simple solutions over complex ones
3. **YAGNI** (You Aren't Gonna Need It) - Don't add functionality until needed
4. **SOLID** principles for OOP

### Kotlin (Android)

**Style Guide**: [Official Kotlin Conventions](https://kotlinlang.org/docs/coding-conventions.html)

**Key Points**:
- Use `camelCase` for functions and variables
- Use `PascalCase` for classes
- Max line length: 120 characters
- Use trailing commas in multi-line declarations
- Prefer `val` over `var` (immutability)
- Use data classes for DTOs/models

**Example**:
```kotlin
data class Message(
    val id: String,
    val content: String,
    val timestamp: Long,
    val sender: User,
)

class ChatViewModel @Inject constructor(
    private val sendMessageUseCase: SendMessageUseCase,
) : ViewModel() {

    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: StateFlow<List<Message>> = _messages.asStateFlow()

    fun sendMessage(content: String) {
        viewModelScope.launch {
            sendMessageUseCase(content)
                .onSuccess { message ->
                    _messages.update { it + message }
                }
                .onFailure { error ->
                    // Handle error
                }
        }
    }
}
```

**Linting**: Run `./gradlew ktlintCheck` before committing

### Swift (iOS)

**Style Guide**: [Google Swift Style Guide](https://google.github.io/swift/)

**Key Points**:
- Use `camelCase` for functions and variables
- Use `PascalCase` for types (classes, structs, enums)
- Max line length: 100 characters
- Use trailing commas in multi-line arrays/dicts
- Prefer `let` over `var` (immutability)
- Use structs for models (value types)

**Example**:
```swift
struct Message: Identifiable, Codable {
    let id: String
    let content: String
    let timestamp: Date
    let sender: User
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []

    private let sendMessageUseCase: SendMessageUseCase

    init(sendMessageUseCase: SendMessageUseCase) {
        self.sendMessageUseCase = sendMessageUseCase
    }

    func sendMessage(_ content: String) async {
        do {
            let message = try await sendMessageUseCase.execute(content: content)
            messages.append(message)
        } catch {
            // Handle error
        }
    }
}
```

**Linting**: Run `swiftlint` before committing

### TypeScript (Backend/Web)

**Style Guide**: [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)

**Key Points**:
- Use `camelCase` for functions and variables
- Use `PascalCase` for classes and types
- Max line length: 100 characters
- Use semicolons
- Prefer `const` over `let` (never use `var`)
- Use async/await over promises
- Use type annotations for function signatures

**Example**:
```typescript
interface Message {
  id: string;
  content: string;
  timestamp: number;
  userId: string;
}

class ChatService {
  constructor(
    private readonly messageRepository: MessageRepository,
    private readonly aiService: AIService,
  ) {}

  async sendMessage(content: string, userId: string): Promise<Message> {
    const message: Message = {
      id: uuidv4(),
      content,
      timestamp: Date.now(),
      userId,
    };

    await this.messageRepository.save(message);

    // Generate AI response asynchronously
    this.aiService.generateResponse(message).catch(console.error);

    return message;
  }
}
```

**Linting**: Run `npm run lint` before committing

### File Organization

**Android**:
```
app/src/main/kotlin/com/codeforgeai/app/
├── presentation/        # UI layer
│   ├── chat/
│   │   ├── ChatScreen.kt
│   │   ├── ChatViewModel.kt
│   │   └── components/
│   │       ├── MessageBubble.kt
│   │       └── InputBar.kt
├── domain/              # Business logic
│   ├── usecases/
│   ├── models/
│   └── repositories/
└── data/                # Data layer
    ├── repositories/
    ├── local/
    └── remote/
```

**iOS**:
```
CodeForgeAI/
├── Presentation/
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   ├── ChatViewModel.swift
│   │   └── Components/
│   │       ├── MessageBubble.swift
│   │       └── InputBar.swift
├── Domain/
│   ├── UseCases/
│   ├── Models/
│   └── Repositories/
└── Data/
    ├── Repositories/
    ├── Local/
    └── Remote/
```

## Testing Requirements

### Coverage Targets
- **Unit Tests**: 80% coverage minimum
- **Integration Tests**: Critical paths covered
- **UI Tests**: Key user flows tested

### Android Testing

**Unit Tests** (JUnit + Kotest):
```kotlin
class SendMessageUseCaseTest {
    private lateinit var useCase: SendMessageUseCase
    private lateinit var repository: ChatRepository

    @Before
    fun setup() {
        repository = mockk()
        useCase = SendMessageUseCase(repository)
    }

    @Test
    fun `sendMessage should save message to repository`() = runTest {
        // Given
        val content = "Hello, world!"
        coEvery { repository.saveMessage(any()) } returns Result.success(mockMessage)

        // When
        val result = useCase(content)

        // Then
        assertTrue(result.isSuccess)
        coVerify { repository.saveMessage(any()) }
    }
}
```

**UI Tests** (Espresso + Compose Testing):
```kotlin
@Test
fun whenUserTypeMessage_andClicksSend_messageShouldAppear() {
    composeTestRule.setContent {
        ChatScreen(viewModel = viewModel)
    }

    composeTestRule.onNodeWithTag("input_field").performTextInput("Hello")
    composeTestRule.onNodeWithTag("send_button").performClick()

    composeTestRule.onNodeWithText("Hello").assertExists()
}
```

**Run Tests**:
```bash
./gradlew test
./gradlew connectedAndroidTest
```

### iOS Testing

**Unit Tests** (XCTest):
```swift
class SendMessageUseCaseTests: XCTestCase {
    var sut: SendMessageUseCase!
    var mockRepository: MockChatRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockChatRepository()
        sut = SendMessageUseCase(repository: mockRepository)
    }

    func testSendMessage_shouldSaveToRepository() async throws {
        // Given
        let content = "Hello, world!"

        // When
        let message = try await sut.execute(content: content)

        // Then
        XCTAssertTrue(mockRepository.saveMessageCalled)
        XCTAssertEqual(message.content, content)
    }
}
```

**UI Tests** (XCUITest):
```swift
func testSendMessage_appearsInChatView() {
    let app = XCUIApplication()
    app.launch()

    let inputField = app.textFields["inputField"]
    inputField.tap()
    inputField.typeText("Hello")

    app.buttons["sendButton"].tap()

    XCTAssertTrue(app.staticTexts["Hello"].exists)
}
```

**Run Tests**:
```bash
xcodebuild test -scheme CodeForgeAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Backend Testing

**Unit Tests** (Jest):
```typescript
describe('ChatService', () => {
  let service: ChatService;
  let mockRepository: jest.Mocked<MessageRepository>;

  beforeEach(() => {
    mockRepository = {
      save: jest.fn(),
    } as any;
    service = new ChatService(mockRepository, mockAIService);
  });

  it('should save message to repository', async () => {
    const message = await service.sendMessage('Hello', 'user-123');

    expect(mockRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({ content: 'Hello' }),
    );
  });
});
```

**Run Tests**:
```bash
npm test
npm run test:coverage
```

## Pull Request Process

### PR Template
When creating a PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issue
Closes #<issue_number>

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)
[Add screenshots or GIFs demonstrating the changes]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass locally
- [ ] Dependent changes merged
```

### PR Review Process

1. **Automated Checks**: CI pipeline runs linters, tests, builds
2. **Code Review**: At least one maintainer reviews
3. **Feedback**: Address review comments
4. **Approval**: Once approved, PR is merged by maintainer
5. **Cleanup**: Delete feature branch after merge

### Review Criteria
Reviewers check for:
- Code quality and readability
- Test coverage
- Documentation
- Performance implications
- Security considerations
- Breaking changes

## Issue Guidelines

### Reporting Bugs

**Template**:
```markdown
**Describe the Bug**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Tap on '...'
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Screenshots**
If applicable, add screenshots

**Environment**
- Device: [e.g. iPhone 15 Pro]
- OS: [e.g. iOS 18.0]
- App Version: [e.g. 1.2.3]

**Additional Context**
Any other relevant information
```

### Requesting Features

**Template**:
```markdown
**Feature Description**
Clear description of the feature

**Problem It Solves**
What user pain point does this address?

**Proposed Solution**
How should this work?

**Alternatives Considered**
What other solutions did you consider?

**Additional Context**
Mockups, examples, etc.
```

### Asking Questions

**Template**:
```markdown
**Question**
Clear, specific question

**Context**
What are you trying to accomplish?

**What I've Tried**
Steps already taken to find the answer

**Environment**
Relevant environment details
```

## Communication Channels

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: General questions, ideas
- **Discord**: Real-time chat, community support
- **Email**: security@codeforgeai.app (security issues), dev@codeforgeai.app (development questions)

## Recognition

Contributors are recognized in:
- [CONTRIBUTORS.md](CONTRIBUTORS.md) file
- Release notes for significant contributions
- Annual contributor highlight blog post

## License

By contributing, you agree that your contributions will be licensed under the same [Apache License 2.0](LICENSE) as the project.

---

**Thank you for contributing to CodeForge AI!** 🚀

Questions? Email contribute@codeforgeai.app or ask in Discord.
