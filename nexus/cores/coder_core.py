"""
Coder Core - The software development engine of Nexus.
Handles code generation, debugging, testing, and deployment.
"""

from typing import Dict, Any, List, Optional
from pathlib import Path
from loguru import logger
import subprocess
import ast
import black
from anthropic import Anthropic
import json


class CoderCore:
    """
    Specialized core for software development.
    Writes clean, tested, production-ready code.
    """

    def __init__(self, config: Config, ai_client: Anthropic, vector_store: Any, ethical_guard: Any):
        """
        Initialize the Coder Core.

        Args:
            config: Configuration instance
            ai_client: AI client for code generation
            vector_store: Vector store for code memory
            ethical_guard: Ethical guard for safety checks
        """
        self.config = config
        self.ai_client = ai_client
        self.vector_store = vector_store
        self.ethical_guard = ethical_guard

        coder_config = config.get("coder", {})
        self.supported_languages = coder_config.get("supported_languages", ["python"])
        self.testing_enabled = coder_config.get("testing_enabled", True)
        self.auto_format = coder_config.get("auto_format", True)
        self.code_review_enabled = coder_config.get("code_review_enabled", True)

        # Project workspace
        self.workspace_path = Path("./data/projects")
        self.workspace_path.mkdir(parents=True, exist_ok=True)

        logger.info(f"Coder Core initialized (languages: {self.supported_languages})")

    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a coding task.

        Args:
            task: Task dictionary with type and parameters

        Returns:
            Result dictionary
        """
        task_type = task.get("type")

        logger.info(f"Coder Core executing task: {task_type}")

        if task_type == "generate_code":
            return self._generate_code(task)
        elif task_type == "review_code":
            return self._review_code(task)
        elif task_type == "debug_code":
            return self._debug_code(task)
        elif task_type == "write_tests":
            return self._write_tests(task)
        elif task_type == "refactor_code":
            return self._refactor_code(task)
        elif task_type == "create_project":
            return self._create_project(task)
        else:
            return {"success": False, "error": f"Unknown task type: {task_type}"}

    def _generate_code(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Generate code based on requirements."""
        requirements = task.get("requirements", "")
        language = task.get("language", "python")
        framework = task.get("framework")

        if language not in self.supported_languages:
            return {"success": False, "error": f"Unsupported language: {language}"}

        logger.info(f"Generating {language} code")

        # Build prompt for code generation
        prompt = self._build_code_generation_prompt(requirements, language, framework)

        try:
            # Generate code using AI
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=4096,
                temperature=0.2,  # Lower temperature for more deterministic code
                messages=[{"role": "user", "content": prompt}],
            )

            code = response.content[0].text

            # Extract code from markdown if present
            code = self._extract_code_from_markdown(code)

            # Format code if enabled
            if self.auto_format and language == "python":
                code = self._format_python_code(code)

            # Validate code
            validation = self._validate_code(code, language)

            if not validation["valid"]:
                logger.warning(f"Generated code has validation issues: {validation['errors']}")

            # Store generated code
            self.vector_store.store(
                collection_type="code",
                content=code,
                metadata={
                    "type": "generated_code",
                    "language": language,
                    "framework": framework,
                    "requirements": requirements[:500],  # Truncate for metadata
                },
            )

            return {
                "success": True,
                "code": code,
                "language": language,
                "validation": validation,
            }

        except Exception as e:
            logger.error(f"Error generating code: {e}")
            return {"success": False, "error": str(e)}

    def _build_code_generation_prompt(
        self, requirements: str, language: str, framework: Optional[str]
    ) -> str:
        """Build a prompt for code generation."""
        framework_info = f" using {framework}" if framework else ""

        prompt = f"""Generate clean, production-ready {language} code{framework_info} based on these requirements:

{requirements}

Requirements:
1. Write clean, well-documented code with docstrings/comments
2. Follow best practices and design patterns
3. Include error handling
4. Make the code modular and reusable
5. Include type hints (if applicable)
6. NO security vulnerabilities (SQL injection, XSS, command injection, etc.)
7. Efficient and performant code

Return ONLY the code, properly formatted. If you need to explain anything, add it as comments in the code."""

        return prompt

    def _extract_code_from_markdown(self, text: str) -> str:
        """Extract code from markdown code blocks."""
        # Look for code blocks
        if "```" in text:
            # Find the code block
            parts = text.split("```")
            if len(parts) >= 3:
                code_block = parts[1]
                # Remove language identifier if present
                lines = code_block.split("\n")
                if lines[0].strip() in ["python", "javascript", "typescript", "rust", "go", "js", "ts"]:
                    return "\n".join(lines[1:])
                return code_block
        return text

    def _format_python_code(self, code: str) -> str:
        """Format Python code using Black."""
        try:
            formatted = black.format_str(code, mode=black.Mode())
            return formatted
        except Exception as e:
            logger.warning(f"Could not format code with Black: {e}")
            return code

    def _validate_code(self, code: str, language: str) -> Dict[str, Any]:
        """Validate code for syntax and basic security issues."""
        validation = {
            "valid": True,
            "errors": [],
            "warnings": [],
        }

        if language == "python":
            # Check Python syntax
            try:
                ast.parse(code)
            except SyntaxError as e:
                validation["valid"] = False
                validation["errors"].append(f"Syntax error: {e}")

            # Basic security checks
            dangerous_patterns = [
                ("eval(", "Use of eval() is dangerous"),
                ("exec(", "Use of exec() is dangerous"),
                ("__import__", "Dynamic imports can be unsafe"),
                ("os.system(", "Use of os.system() can lead to command injection"),
                ("subprocess.call(", "Ensure subprocess calls are safe from injection"),
            ]

            for pattern, warning in dangerous_patterns:
                if pattern in code:
                    validation["warnings"].append(warning)

        return validation

    def _review_code(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Review code for quality and issues."""
        code = task.get("code", "")
        language = task.get("language", "python")

        logger.info("Performing code review")

        prompt = f"""Review this {language} code for:
1. Code quality and readability
2. Best practices adherence
3. Potential bugs
4. Security vulnerabilities
5. Performance issues
6. Suggestions for improvement

Code:
```{language}
{code}
```

Provide a detailed review with specific line references where applicable."""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=2048,
                temperature=0.3,
                messages=[{"role": "user", "content": prompt}],
            )

            review = response.content[0].text

            return {
                "success": True,
                "review": review,
                "language": language,
            }

        except Exception as e:
            logger.error(f"Error during code review: {e}")
            return {"success": False, "error": str(e)}

    def _debug_code(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Debug code to find and fix issues."""
        code = task.get("code", "")
        error_message = task.get("error", "")
        language = task.get("language", "python")

        logger.info("Debugging code")

        prompt = f"""Debug this {language} code that is producing an error:

Error: {error_message}

Code:
```{language}
{code}
```

Provide:
1. Explanation of what's causing the error
2. Fixed version of the code
3. Explanation of the fix"""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=2048,
                temperature=0.2,
                messages=[{"role": "user", "content": prompt}],
            )

            debug_result = response.content[0].text

            return {
                "success": True,
                "debug_result": debug_result,
                "language": language,
            }

        except Exception as e:
            logger.error(f"Error during debugging: {e}")
            return {"success": False, "error": str(e)}

    def _write_tests(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Write tests for given code."""
        code = task.get("code", "")
        language = task.get("language", "python")
        test_framework = task.get("test_framework", "pytest")

        logger.info(f"Writing tests using {test_framework}")

        prompt = f"""Write comprehensive tests for this {language} code using {test_framework}:

Code:
```{language}
{code}
```

Include:
1. Unit tests for all functions/methods
2. Edge cases and error conditions
3. Clear test names and documentation
4. Proper setup and teardown if needed"""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=2048,
                temperature=0.2,
                messages=[{"role": "user", "content": prompt}],
            )

            tests = response.content[0].text
            tests = self._extract_code_from_markdown(tests)

            return {
                "success": True,
                "tests": tests,
                "language": language,
                "framework": test_framework,
            }

        except Exception as e:
            logger.error(f"Error writing tests: {e}")
            return {"success": False, "error": str(e)}

    def _refactor_code(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Refactor code to improve quality."""
        code = task.get("code", "")
        language = task.get("language", "python")
        goals = task.get("goals", "improve readability and maintainability")

        logger.info("Refactoring code")

        prompt = f"""Refactor this {language} code to {goals}:

Code:
```{language}
{code}
```

Provide:
1. Refactored code
2. Explanation of changes made
3. Benefits of the refactoring"""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=2048,
                temperature=0.2,
                messages=[{"role": "user", "content": prompt}],
            )

            result = response.content[0].text
            refactored_code = self._extract_code_from_markdown(result)

            return {
                "success": True,
                "refactored_code": refactored_code,
                "full_result": result,
                "language": language,
            }

        except Exception as e:
            logger.error(f"Error refactoring code: {e}")
            return {"success": False, "error": str(e)}

    def _create_project(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new software project from scratch."""
        project_name = task.get("name", "untitled_project")
        description = task.get("description", "")
        language = task.get("language", "python")
        framework = task.get("framework")

        logger.info(f"Creating new project: {project_name}")

        # Check ethical approval for project creation
        if not self.ethical_guard.check_action(
            "create_project",
            f"Create project: {project_name}",
            {"name": project_name, "description": description},
        ):
            return {"success": False, "error": "Project creation not approved"}

        project_path = self.workspace_path / project_name
        project_path.mkdir(parents=True, exist_ok=True)

        # Generate project structure based on language
        if language == "python":
            self._create_python_project(project_path, project_name, description, framework)
        elif language in ["javascript", "typescript"]:
            self._create_js_project(project_path, project_name, description, framework)
        else:
            return {"success": False, "error": f"Project creation for {language} not yet supported"}

        return {
            "success": True,
            "project_path": str(project_path),
            "project_name": project_name,
            "language": language,
        }

    def _create_python_project(
        self, path: Path, name: str, description: str, framework: Optional[str]
    ) -> None:
        """Create a Python project structure."""
        # Create basic structure
        (path / name).mkdir(exist_ok=True)
        (path / "tests").mkdir(exist_ok=True)
        (path / name / "__init__.py").write_text(f'"""{ description}"""\n\n__version__ = "0.1.0"\n')
        (path / "tests" / "__init__.py").write_text("")

        # Create README
        readme = f"""# {name}

{description}

## Installation

```bash
pip install -e .
```

## Usage

```python
import {name}
```

## Development

```bash
pip install -e .[dev]
pytest
```
"""
        (path / "README.md").write_text(readme)

        # Create setup.py
        setup_py = f"""from setuptools import setup, find_packages

setup(
    name="{name}",
    version="0.1.0",
    description="{description}",
    packages=find_packages(),
    python_requires=">=3.8",
    install_requires=[],
    extras_require={{
        "dev": ["pytest", "black", "pylint"],
    }},
)
"""
        (path / "setup.py").write_text(setup_py)

        # Create .gitignore
        gitignore = """__pycache__/
*.py[cod]
*$py.class
.pytest_cache/
dist/
build/
*.egg-info/
.env
"""
        (path / ".gitignore").write_text(gitignore)

        logger.info(f"Created Python project structure at {path}")

    def _create_js_project(
        self, path: Path, name: str, description: str, framework: Optional[str]
    ) -> None:
        """Create a JavaScript/TypeScript project structure."""
        # Create package.json
        package_json = {
            "name": name,
            "version": "0.1.0",
            "description": description,
            "main": "index.js",
            "scripts": {
                "test": "jest",
                "start": "node index.js",
            },
            "keywords": [],
            "author": "Nexus",
            "license": "MIT",
        }

        (path / "package.json").write_text(json.dumps(package_json, indent=2))

        # Create index.js
        (path / "index.js").write_text("// Entry point\n\nconsole.log('Hello from Nexus!');\n")

        # Create README
        readme = f"""# {name}

{description}

## Installation

```bash
npm install
```

## Usage

```bash
npm start
```
"""
        (path / "README.md").write_text(readme)

        logger.info(f"Created JavaScript project structure at {path}")
