# OpenRouter AI VS Code Extension

A streamlined AI chat assistant using OpenRouter API with access to multiple AI models (DeepSeek, Claude, GPT, Llama, etc.) and code analysis capabilities.

- 🤖 **AI Chat** with multiple models (OpenRouter API)
- 🔧 **Diff Application System** for code changes
- 💾 **Help File System** for saving suggestions
- 🎯 **VS Code Integration** with commands and UI

## Features

- 💬 **Chat with Multiple AI Models**: Access to DeepSeek, Claude, GPT, Llama, and more through OpenRouter
- 🔑 **Simple API Configuration**: Enter your OpenRouter API key once
- 🎛️ **Model Selection**: Switch between different AI models easily
- 📄 **Code Context**: Load code from active editor into chat
- 💭 **Smart Actions**: Request code comments or changes
- 🎯 **Streaming Responses**: Real-time AI responses
- 💾 **Persistent Configuration**: Your settings are saved securely
- 🌐 **OpenRouter Integration**: Unified API for multiple AI providers


### 🔧 Diff Application System
- Apply unified diffs from AI responses
- Validate diff syntax before applying
- Preview changes before committing
- Save AI suggestions to help files
- Apply saved suggestions from help files
- Create diffs between code versions
- Extract diffs from AI responses automatically

### 🎯 VS Code Integration
- Sidebar chat panel
- Context menu commands
- Command palette integration
- Editor context awareness
- File-specific suggestions

### 💾 Help File System
- Save AI suggestions as \`*_help.json\` files
- Review and apply suggestions later
- Team collaboration on code reviews
- Version control friendly

openrouter-chat/
├── src/                          # TypeScript source code
│   ├── extension.ts              # Main extension entry point
│   ├── webview.ts                # Webview panel with chat interface
│   └── diff_application.ts       # Core diff application system
├── scripts/                      # Python scripts
│   └── diff_processor.py         # Python backend for complex diff operations
├── media/                        # Assets and icons
│   └── logo.png                  # Extension logo
├── examples/                     # Example files
│   ├── example.py                # Example Python file
│   ├── example.diff              # Example diff file
│   └── example_py_help.json      # Example AI suggestions file
├── node_modules/                 # Node.js dependencies (auto-generated)
├── out/                          # Compiled JavaScript (auto-generated)
├── package.json                  # Extension manifest
├── tsconfig.json                 # TypeScript configuration
├── requirements.txt              # Python dependencies
├── README.md                     # This documentation
└── LICENSE.md                    # MIT License

## Configuration

1. Get an OpenRouter API key from: [https://openrouter.ai/settings/keys](https://openrouter.ai/settings/keys)
2. Open the AI Assistant panel in VS Code
3. Click Settings ⚙️
4. Enter your API key
5. Select a model (DeepSeek R1 recommended for code)
6. Save configuration

## Usage

### Basic Chat
1. Open AI Assistant panel
2. Type your question
3. Press Enter or click Send
4. AI responds in real-time

### Code Review
1. Open a code file
2. Right-click in editor → "Request Code Review from AI"
3. Or click "Load Active File" in chat
4. AI will analyze and suggest improvements

### Applying Diffs
When AI suggests code changes:
- **Preview**: See what will change
- **Apply**: Apply the diff immediately
- **Save**: Save to help file for later
- **Validate**: Check diff syntax first

### Help Files
- AI suggestions are saved to \`[filename]_[extension]_help.json\`
- Use "Apply Solution from Comments" command to apply saved suggestions
- Help files can be shared with team members
- Works with version control systems

## Commands

### Chat Commands
- **AI Assistant: Focus AI Chat** - Open chat panel
- **AI Assistant: Clear Chat History** - Clear all messages
- **AI Assistant: Open Settings** - Configure extension
- **AI Assistant: Request Code Review** - Get AI code review
- **AI Assistant: Apply Last AI Suggestion** - Quick apply

### Diff Commands
- **AI Assistant: Apply Solution from Comments** - Apply from help file
- **AI Assistant: Extract and Apply Diff from AI** - Apply AI response diff
- **AI Assistant: Validate Diff Syntax** - Check diff format
- **AI Assistant: Create Diff Between Versions** - Generate diff
- **AI Assistant: Generate Git Diff** - Git integration

## Supported Models

- **DeepSeek R1 8B** - Excellent for code and reasoning
- **DeepSeek Chat** - General purpose
- **DeepSeek Coder** - Code specialized
- **Google Gemini 2.0 Flash** - Fast and free tier
- **Meta Llama 3.3 70B** - Powerful open model
- **Anthropic Claude 3.5 Haiku** - Fast and capable
- **OpenAI GPT-4o Mini** - Cost-effective GPT-4
- **Microsoft WizardLM 2** - Large model for complex tasks
- **Qwen 2.5 32B** - Balanced model for general tasks

## Example Workflow

1. Write code in VS Code
2. Chat with AI about improvements
3. Request code review for specific files
4. Preview AI suggestions as diffs
5. Apply changes with one click
6. Save suggestions to help files for team review
7. Collaborate using help files and version control

## Privacy & Security

- API keys stored in VS Code global state (encrypted)
- No code sent to AI without your permission
- Help files stored locally with your code
- Open source - inspect the code yourself

## Troubleshooting

### API Key Issues
- Ensure key is valid at [https://openrouter.ai/account](https://openrouter.ai/account)
- Check for sufficient credits
- Verify network connectivity

### Diff Application Issues
- Ensure diffs are in proper unified format
- Use "Validate Diff Syntax" command
- Check line numbers match your file

### Extension Issues
- Reload VS Code window
- Check Output panel for errors
- Reinstall extension if needed

## Development

\`\`\`bash
# Clone and open in VS Code
code .

# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Start debugging (F5)
\`\`\`

## Pricing

- OpenRouter uses pay-per-token pricing
- Costs vary by model (check [openrouter.ai/pricing](https://openrouter.ai/pricing))
- Some models have free tiers
- Monitor usage at [openrouter.ai/account](https://openrouter.ai/account)

## License

MIT License - See LICENSE file

## Acknowledgments

- OpenRouter API for multi-model access
- VS Code Extension API
- Community contributors
