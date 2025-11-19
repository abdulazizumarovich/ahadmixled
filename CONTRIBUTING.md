# Contributing to Android LED Player

First off, thank you for considering contributing to Android LED Player! It's people like you that make this project great.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps to reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed and what behavior you expected**
* **Include screenshots if possible**
* **Provide device information** (Android version, device model, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a detailed description of the suggested enhancement**
* **Explain why this enhancement would be useful**
* **List examples of how this enhancement would be used**

### Pull Requests

* Fill in the required template
* Follow the Kotlin coding style
* Include appropriate test coverage
* Update documentation as needed
* End all files with a newline

## Development Process

### Setup Development Environment

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/ahadmixled.git`
3. Add upstream remote: `git remote add upstream https://github.com/Jaloliddin-Fozilov/ahadmixled.git`
4. Create a branch: `git checkout -b feature/your-feature-name`

### Making Changes

1. **Write Clean Code**
   - Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
   - Use meaningful variable and function names
   - Keep functions small and focused
   - Add comments for complex logic

2. **Follow Architecture**
   - Maintain Clean Architecture layers
   - Keep domain layer independent
   - Use dependency injection (Hilt)
   - Follow MVVM pattern in presentation layer

3. **Write Tests**
   - Add unit tests for new features
   - Maintain or improve test coverage
   - Test edge cases and error scenarios

4. **Update Documentation**
   - Update README.md if needed
   - Add KDoc comments for public APIs
   - Update CHANGELOG.md

### Code Style

```kotlin
// Good
class MediaPlayerManager @Inject constructor(
    private val context: Context,
    private val webSocketManager: WebSocketManager
) {
    fun playMedia(media: Media) {
        // Implementation
    }
}

// Bad
class MediaPlayerManager @Inject constructor(private val context: Context, private val webSocketManager: WebSocketManager) {
    fun playMedia(media: Media){
        // Implementation
    }
}
```

### Commit Messages

* Use present tense ("Add feature" not "Added feature")
* Use imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit first line to 72 characters
* Reference issues and pull requests

```
Add WebSocket reconnection logic

- Implement exponential backoff strategy
- Add maximum retry limit
- Update documentation

Fixes #123
```

### Testing

Before submitting a pull request:

```bash
# Run unit tests
./gradlew testDebugUnitTest

# Run lint checks
./gradlew lintDebug

# Build the app
./gradlew assembleDebug
```

### Submitting Changes

1. Push to your fork: `git push origin feature/your-feature-name`
2. Open a Pull Request against `main` branch
3. Fill in the PR template
4. Wait for review and address feedback

## Project Structure

```
app/
├── data/          # Data layer
├── domain/        # Domain layer (business logic)
├── presentation/  # UI layer (Activities, ViewModels)
├── di/            # Dependency injection
└── util/          # Utilities
```

## Important Guidelines

### Do's
✅ Write clean, readable code
✅ Add tests for new features
✅ Update documentation
✅ Follow existing patterns
✅ Use Timber for logging
✅ Handle errors gracefully

### Don'ts
❌ Don't break existing functionality
❌ Don't ignore lint warnings
❌ Don't commit commented-out code
❌ Don't hardcode values
❌ Don't skip error handling
❌ Don't expose sensitive data

## Resources

- [Kotlin Documentation](https://kotlinlang.org/docs/home.html)
- [Android Developer Guide](https://developer.android.com/)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Hilt Documentation](https://dagger.dev/hilt/)

## Questions?

Feel free to open an issue with your question or contact the maintainers directly.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing! 🎉
