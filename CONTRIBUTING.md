# Contributing to Skoxie ArgoCD

Thank you for your interest in contributing to this project! This guide will help you get started.

## Code of Conduct

- Be respectful and inclusive
- Help others learn
- Provide constructive feedback
- Keep discussions on topic

## How to Contribute

### Reporting Issues

1. Check if the issue already exists
2. Provide clear steps to reproduce
3. Include relevant logs and errors
4. Describe expected vs actual behavior

### Suggesting Enhancements

1. Clearly describe the enhancement
2. Explain why it would be useful
3. Provide examples if possible
4. Consider backward compatibility

### Adding New Applications

To contribute a new example application:

1. Create a new directory under `apps/`
2. Add all necessary manifests (Deployment, Service, IngressRoute)
3. Include a README explaining the app
4. Ensure it follows the existing patterns
5. Test thoroughly before submitting

Example structure:
```
apps/
├── my-app/
│   ├── README.md
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingressroute.yaml
```

### Adding New Infrastructure Components

1. Create a directory under `infrastructure/`
2. Add all necessary manifests
3. Create an Application manifest in `bootstrap/`
4. Update the main README
5. Add troubleshooting steps to SETUP.md
6. Test the deployment

### Improving Documentation

Documentation improvements are always welcome:

- Fix typos or unclear instructions
- Add missing examples
- Improve troubleshooting guides
- Add diagrams or visualizations
- Update outdated information

## Development Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
git clone https://github.com/YOUR_USERNAME/skoxie-argo.git
cd skoxie-argo
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring

### 3. Make Changes

- Follow existing code style
- Keep changes focused and atomic
- Test your changes thoroughly
- Update documentation as needed

### 4. Test Your Changes

```bash
# Test configuration
./configure.sh

# Validate YAML syntax
find . -name "*.yaml" -exec yamllint {} \;

# Test deployment (in test cluster)
kubectl apply -f root-app.yaml

# Verify applications
kubectl get applications -n argocd
```

### 5. Commit Changes

Follow conventional commit format:

```bash
git add .
git commit -m "type(scope): description

Longer explanation if needed.

Fixes #123"
```

Commit types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance

Examples:
```
feat(traefik): add HTTP/3 support
fix(cert-manager): correct DNS challenge configuration
docs(readme): add installation video link
```

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear title and description
- Reference any related issues
- Explain what changed and why
- Include screenshots if UI changes
- List testing performed

## Code Style Guidelines

### YAML Files

- Use 2 spaces for indentation
- No tabs
- Keep lines under 120 characters
- Add comments for complex configurations
- Use meaningful names

Example:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-namespace
  labels:
    app: my-app
    version: "1.0"
spec:
  replicas: 2
  # More configuration...
```

### Shell Scripts

- Use `#!/bin/bash` shebang
- Add description at top
- Use `set -e` for error handling
- Comment complex logic
- Use meaningful variable names

Example:
```bash
#!/bin/bash

# Script to deploy applications
# Usage: ./deploy.sh [app-name]

set -e

APP_NAME="${1:-all}"
echo "Deploying ${APP_NAME}..."
```

### Documentation

- Use clear, concise language
- Include examples
- Add code blocks with syntax highlighting
- Use lists and headings for structure
- Keep sections focused

## Testing

### Manual Testing

1. Deploy to test cluster
2. Verify all applications are healthy
3. Test ingress routes
4. Check certificate issuance
5. Verify DDNS updates
6. Test authentication if applicable

### Automated Testing (Future)

- Validate YAML syntax
- Test Kubernetes manifests
- Integration tests
- E2E tests

## Documentation Standards

### README Structure

- Clear introduction
- Prerequisites
- Quick start guide
- Detailed documentation
- Troubleshooting
- Contributing section

### Code Comments

Add comments for:
- Complex logic
- Configuration options
- Security considerations
- Performance notes
- TODOs

## Pull Request Review Process

### What We Look For

1. **Functionality**: Does it work as intended?
2. **Code Quality**: Is it clean and maintainable?
3. **Documentation**: Is it well documented?
4. **Testing**: Has it been tested?
5. **Backward Compatibility**: Does it break existing setups?

### Review Timeline

- Initial review: Within 1-3 days
- Follow-up: As needed
- Merge: After approval and CI passes

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Issues**: Create a GitHub Issue
- **Security**: Email security concerns privately
- **Chat**: Join community chat (if available)

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in commit history

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Community

### Be Respectful

- Respect different opinions
- Be patient with newcomers
- Provide constructive feedback
- Help others learn

### Good Practices

- Respond to comments on your PRs
- Help review others' PRs
- Share knowledge
- Improve documentation
- Report bugs you find

## Examples of Good Contributions

### Adding a New App

```yaml
# apps/grafana/grafana-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    # ... rest of deployment
---
# Service and IngressRoute
```

### Improving Documentation

- Add missing setup steps
- Create video tutorials
- Write blog posts
- Create diagrams
- Translate documentation

### Bug Fixes

- Fix certificate renewal issues
- Correct YAML syntax errors
- Update deprecated APIs
- Fix broken links

## Advanced Contributions

### Architecture Changes

For major architectural changes:
1. Open an issue for discussion first
2. Provide detailed proposal
3. Get feedback from maintainers
4. Create RFC if needed

### Performance Improvements

- Profile before optimizing
- Benchmark changes
- Document performance gains
- Consider resource constraints

### Security Enhancements

- Follow security best practices
- Report vulnerabilities privately first
- Provide patches with disclosures
- Update security documentation

## Thank You!

Your contributions make this project better for everyone. Thank you for taking the time to contribute! 🎉

---

Questions? Open an issue or start a discussion!
