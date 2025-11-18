# Contributing to Pulse App

Welcome! We're excited to have you contribute to the Pulse App. This guide will help you get started.

---

## **Code of Conduct**

Be respectful, inclusive, and constructive in all interactions. We're building a community where everyone feels welcome.

---

## **Getting Started**

1. **Fork the repository** and clone it locally
2. **Create a branch** for your work: `git checkout -b feature/your-feature`
3. **Make your changes** and test thoroughly
4. **Submit a pull request** with a clear description

See [PROJECT_SETUP_GUIDE.md](./PROJECT_SETUP_GUIDE.md) for detailed development setup.

---

## **Development Workflow**

### **1. Create Feature Branch**

```bash
git checkout -b feature/short-description
# Examples:
# feature/routine-engine-mvp
# fix/crash-on-login
# docs/update-architecture
```

### **2. Make Changes**

- Keep commits small and focused
- Write descriptive commit messages
- Add tests for new features
- Update documentation

### **3. Test Locally**

```bash
# iOS
cd ios && xcodebuild test

# Android
cd android && ./gradlew test

# Backend
cd backend && npm test
```

### **4. Push & Create PR**

```bash
git push -u origin feature/your-feature
# Create PR on GitHub with template
```

---

## **Commit Message Format**

Follow conventional commits:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### **Type**

- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation
- `style` — Code style (formatting, etc)
- `refactor` — Code refactoring
- `perf` — Performance improvement
- `test` — Test addition/modification
- `chore` — Build, dependencies, tooling

### **Scope**

- `ios` — iOS app
- `android` — Android app
- `backend` — Cloud functions
- `docs` — Documentation

### **Examples**

```
feat(ios): implement routine detail screen

- Add ability to start/pause routines
- Display task progress with animations
- Show completion summary

Closes #123
```

```
fix(android): resolve crash on community feed scroll

Previously app would crash when scrolling past 50 posts due to
memory leak in post adapter. Now using WeakReference for listeners.

Fixes #456
```

---

## **Pull Request Process**

### **Before Submitting**

- [ ] All tests pass locally
- [ ] Code follows style guide
- [ ] PR description is clear and complete
- [ ] No unnecessary files committed
- [ ] Screenshots/videos for UI changes

### **PR Description Template**

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update

## Related Issue
Fixes #(issue number)

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## Checklist
- [ ] Code follows style guide
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings introduced
```

### **Code Review**

- Minimum 2 approvals required
- All comments must be addressed
- All checks must pass
- Maintainers can request changes

---

## **Code Style Guidelines**

### **Swift (iOS)**

```swift
// ✅ Good
func loadRoutines() async throws -> [Routine] {
    guard let url = URL(string: "https://api.pulse.app/routines") else {
        throw URLError(.badURL)
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Routine].self, from: data)
}

// ❌ Avoid
func loadRoutines(callback: @escaping ([Routine]?) -> Void) {
    // Callback hell
}
```

**Style Guide:**
- Use async/await (not callbacks)
- Prefix computed properties with get
- Use `guard let` for optionals
- 2-space indentation
- Max line length: 100 characters

**Tools:**
- SwiftFormat: `brew install swiftformat`
- SwiftLint: `brew install swiftlint`

### **Kotlin (Android)**

```kotlin
// ✅ Good
class RoutineViewModel : ViewModel() {
    private val _routines = MutableLiveData<List<Routine>>()
    val routines: LiveData<List<Routine>> = _routines

    fun loadRoutines() {
        viewModelScope.launch {
            try {
                _routines.value = apiService.fetchRoutines()
            } catch (e: Exception) {
                // Handle error
            }
        }
    }
}

// ❌ Avoid
class RoutineActivity : AppCompatActivity() {
    fun loadRoutines() {
        // Heavy logic in Activity
    }
}
```

**Style Guide:**
- MVVM architecture (ViewModel + Repository)
- Use Coroutines (not callbacks)
- 4-space indentation
- Max line length: 100 characters
- Use meaningful variable names

**Tools:**
- Ktlint: `./gradlew ktlintFormat`
- Android Studio inspections

### **TypeScript (Backend)**

```typescript
// ✅ Good
export async function createRoutine(
  userId: string,
  routine: Routine,
): Promise<RoutineResponse> {
  if (!isValidRoutine(routine)) {
    throw new HttpsError('invalid-argument', 'Invalid routine');
  }

  const docRef = await db
    .collection('users')
    .doc(userId)
    .collection('routines')
    .add(routine);

  return { id: docRef.id, ...routine };
}

// ❌ Avoid
exports.createRoutine = (req, res) => {
  // Callback hell, no error handling
};
```

**Style Guide:**
- Use TypeScript (strict mode)
- Async/await (no callbacks)
- 2-space indentation
- Max line length: 80 characters
- Document with JSDoc

**Tools:**
- Prettier: `npx prettier --write .`
- ESLint: `npm run lint`

---

## **Testing Guidelines**

### **Test Coverage**

- Target: 70%+ coverage
- Every public method should have tests
- Include both happy path & error cases
- Write tests before code (TDD where possible)

### **iOS Tests**

```swift
@MainActor
final class RoutineViewModelTests: XCTestCase {
    var sut: RoutineViewModel!
    var mockService: MockRoutineService!

    override func setUp() {
        super.setUp()
        mockService = MockRoutineService()
        sut = RoutineViewModel(service: mockService)
    }

    func testLoadRoutinesSuccess() async throws {
        let expected = [Routine.mock()]
        mockService.routines = expected

        await sut.loadRoutines()

        XCTAssertEqual(sut.routines, expected)
    }
}
```

### **Android Tests**

```kotlin
class RoutineViewModelTest {
    private lateinit var viewModel: RoutineViewModel
    private val mockService = mockk<RoutineService>()

    @Before
    fun setUp() {
        viewModel = RoutineViewModel(mockService)
    }

    @Test
    fun loadRoutines_success() = runTest {
        val expected = listOf(Routine.mock())
        coEvery { mockService.getRoutines() } returns expected

        viewModel.loadRoutines()

        assertEquals(expected, viewModel.routines.value)
    }
}
```

### **Backend Tests**

```typescript
describe('createRoutine', () => {
  it('should create routine successfully', async () => {
    const userId = 'user123';
    const routine = { name: 'Morning', tasks: [] };

    const result = await createRoutine(userId, routine);

    expect(result).toHaveProperty('id');
    expect(result.name).toBe('Morning');
  });

  it('should throw on invalid routine', async () => {
    const userId = 'user123';
    const routine = { name: '' }; // Invalid: empty name

    await expect(createRoutine(userId, routine))
      .rejects
      .toThrow('Invalid routine');
  });
});
```

---

## **Documentation**

When adding features, update:

1. **Code comments** — Complex logic should be explained
2. **API docs** — Public method signatures
3. **README.md** — High-level overview
4. **Architecture docs** — If changing system design

### **Documentation Example**

```swift
/// Loads user's routines from Firestore.
///
/// - Returns: Array of Routine objects, newest first
/// - Throws: `RoutineError.fetchFailed` if network error
/// - Note: Results are cached locally for offline access
public func loadRoutines() async throws -> [Routine] {
    // Implementation
}
```

---

## **Performance Considerations**

### **iOS**

- Avoid blocking main thread
- Use `@MainActor` for UI updates
- Profile with Xcode Instruments
- Keep app launch < 2 seconds

### **Android**

- Use background threads for I/O
- Avoid ANR (Application Not Responding)
- Profile with Android Profiler
- Optimize for low-end devices

### **Backend**

- Keep Cloud Function cold start < 1s
- Optimize Firestore queries
- Implement pagination for large datasets
- Monitor with Firebase Performance

---

## **Security Best Practices**

1. **Never commit secrets** (API keys, passwords, tokens)
2. **Use environment variables** for configuration
3. **Validate all inputs** on frontend and backend
4. **Encrypt sensitive data** at rest and in transit
5. **Request minimum permissions** necessary
6. **Update dependencies** regularly

### **Security Checklist**

- [ ] No secrets in code
- [ ] Input validation added
- [ ] Error messages don't leak info
- [ ] Dependencies are up-to-date
- [ ] Code reviewed for vulnerabilities

---

## **Common Issues & Solutions**

### **Build Failures**

```bash
# iOS
rm -rf Pods/ Podfile.lock
pod install --repo-update

# Android
./gradlew clean
./gradlew build
```

### **Test Failures**

- Check latest dependencies
- Verify mock data matches API schema
- Run tests in isolation: `xcodebuild test -only RoutineViewModelTests`

### **Git Conflicts**

```bash
# View conflicts
git status

# Resolve and stage
git add <file>
git commit -m "Resolve merge conflict"
```

---

## **Getting Help**

- **Slack:** #pulse-dev channel
- **Issues:** Comment on related GitHub issue
- **Discussions:** Start a discussion for questions
- **Email:** dev@pulseapp.io

---

## **Code Review Checklist**

When reviewing code, check:

- [ ] Solves the stated problem
- [ ] Code is readable and well-commented
- [ ] Tests cover happy path + errors
- [ ] No performance regressions
- [ ] No security vulnerabilities
- [ ] Follows code style guide
- [ ] Documentation is updated
- [ ] No breaking changes (or justified)

---

## **Merging & Deployment**

Once approved:

1. **Maintainer squashes and merges** PR
2. **Automatic CI/CD** deploys to staging
3. **Tagged releases** deploy to production
4. **Release notes** published

---

## **Thank You!**

We appreciate your contributions. Building Pulse together makes it better for everyone. 🚀

---

**Happy coding!**
