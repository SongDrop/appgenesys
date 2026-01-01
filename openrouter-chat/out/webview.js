"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.openrouterPanel = void 0;
const vscode = require("vscode");
const openai_1 = require("openai");
const path = require("path");
class openrouterPanel {
    constructor(context, diffSystem) {
        this.context = context;
        this._disposables = [];
        this.chatHistory = [];
        this.apiKey = '';
        this.baseURL = 'https://openrouter.ai/api/v1';
        this.model = 'deepseek/deepseek-r1-0528-qwen3-8b';
        this.httpReferer = 'https://github.com';
        this.xTitle = 'OpenRouter Chat VS Code Extension';
        this.openai = null;
        this.abortController = null;
        this.isInitialized = false;
        // Storage keys
        this.CHAT_HISTORY_KEY = 'openrouterChatHistory';
        this.SAVE_SETTING_KEY = 'openrouterSaveChatHistory';
        this.saveChatHistoryEnabled = true;
        // Popular OpenRouter models - Curated from Official List
        this.availableModels = [
            // ===== ORIGINAL MODELS =====
            {
                id: 'deepseek/deepseek-r1-0528-qwen3-8b',
                name: 'DeepSeek R1 8B',
                provider: 'DeepSeek',
                description: 'Reasoning model with 8B parameters, excellent for code and reasoning'
            },
            {
                id: 'deepseek/deepseek-chat',
                name: 'DeepSeek Chat',
                provider: 'DeepSeek',
                description: 'General purpose chat model'
            },
            {
                id: 'deepseek/deepseek-coder',
                name: 'DeepSeek Coder',
                provider: 'DeepSeek',
                description: 'Specialized for code generation and analysis'
            },
            {
                id: 'google/gemini-2.0-flash-exp:free',
                name: 'Gemini 2.0 Flash (Free)',
                provider: 'Google',
                description: 'Fast and capable model, free tier available'
            },
            {
                id: 'meta-llama/llama-3.3-70b-instruct:free',
                name: 'Llama 3.3 70B (Free)',
                provider: 'Meta',
                description: 'Powerful open model, free tier available'
            },
            {
                id: 'anthropic/claude-3.5-haiku',
                name: 'Claude 3.5 Haiku',
                provider: 'Anthropic',
                description: 'Fast and capable model from Anthropic'
            },
            {
                id: 'openai/gpt-4o-mini',
                name: 'GPT-4o Mini',
                provider: 'OpenAI',
                description: 'Cost-effective GPT-4 model'
            },
            // ===== MASSIVE CONTEXT MODELS (1M+ tokens) =====
            {
                id: 'google/gemini-1.5-pro-exp-0801:free',
                name: 'Gemini 1.5 Pro (1M tokens - Free)',
                provider: 'Google',
                description: '🔥 MASSIVE 1 million token context! Best for large codebases'
            },
            {
                id: 'amazon/nova-2-lite-v1:free',
                name: 'Amazon Nova 2 Lite (1M tokens - Free)',
                provider: 'Amazon',
                description: '1 million token context, completely free!'
            },
            {
                id: 'google/gemini-2.5-flash',
                name: 'Gemini 2.5 Flash (1M tokens)',
                provider: 'Google',
                description: '1M context, fast and capable'
            },
            {
                id: 'google/gemini-2.5-pro',
                name: 'Gemini 2.5 Pro (1M tokens)',
                provider: 'Google',
                description: '1M context, most capable Gemini'
            },
            {
                id: 'x-ai/grok-4.1-fast',
                name: 'Grok 4.1 Fast (2M tokens)',
                provider: 'xAI',
                description: 'MASSIVE 2 million token context!'
            },
            {
                id: 'anthropic/claude-sonnet-4.5',
                name: 'Claude Sonnet 4.5 (1M tokens)',
                provider: 'Anthropic',
                description: '1 million token context, very capable'
            },
            // ===== LARGE CONTEXT MODELS (128K-400K) =====
            {
                id: 'mistralai/mistral-large-2512',
                name: 'Mistral Large 3 (262K tokens)',
                provider: 'Mistral',
                description: '262K context, excellent for code'
            },
            {
                id: 'anthropic/claude-opus-4.5',
                name: 'Claude Opus 4.5 (200K tokens)',
                provider: 'Anthropic',
                description: '200K context, most capable Claude'
            },
            {
                id: 'openai/gpt-5.1',
                name: 'GPT-5.1 (400K tokens)',
                provider: 'OpenAI',
                description: '400K context, latest GPT-5'
            },
            {
                id: 'openai/gpt-5.1-codex',
                name: 'GPT-5.1 Codex (400K tokens)',
                provider: 'OpenAI',
                description: '400K context, specialized for code'
            },
            {
                id: 'moonshotai/kimi-linear-48b-a3b-instruct',
                name: 'Kimi Linear 48B (1M tokens)',
                provider: 'MoonshotAI',
                description: '1M context, excellent reasoning'
            },
            {
                id: 'deepseek/deepseek-v3.2',
                name: 'DeepSeek V3.2 (164K tokens)',
                provider: 'DeepSeek',
                description: '164K context, latest DeepSeek'
            },
            // ===== FREE TIER GEMS =====
            {
                id: 'arcee-ai/trinity-mini:free',
                name: 'Trinity Mini (131K tokens - Free)',
                provider: 'Arcee AI',
                description: '131K context, completely free'
            },
            {
                id: 'tngtech/tng-r1t-chimera:free',
                name: 'R1T Chimera (164K tokens - Free)',
                provider: 'TNG',
                description: '164K context, free reasoning model'
            },
            {
                id: 'allenai/olmo-3-32b-think:free',
                name: 'Olmo 3 32B Think (66K tokens - Free)',
                provider: 'AllenAI',
                description: 'Reasoning model, completely free'
            },
            {
                id: 'kwaipilot/kat-coder-pro:free',
                name: 'KAT Coder Pro (256K tokens - Free)',
                provider: 'Kwaipilot',
                description: '256K context for coding, free!'
            },
            {
                id: 'alibaba/tongyi-deepresearch-30b-a3b:free',
                name: 'Tongyi DeepResearch (131K tokens - Free)',
                provider: 'Alibaba',
                description: 'Research-focused, 131K context, free'
            },
            // ===== CODING SPECIALISTS =====
            {
                id: 'mistralai/codestral-2508',
                name: 'Codestral 2508 (256K tokens)',
                provider: 'Mistral',
                description: '256K context, specialized for coding'
            },
            {
                id: 'qwen/qwen3-coder',
                name: 'Qwen3 Coder 480B (262K tokens)',
                provider: 'Qwen',
                description: '480B parameter coder, 262K context'
            },
            {
                id: 'x-ai/grok-code-fast-1',
                name: 'Grok Code Fast 1 (256K tokens)',
                provider: 'xAI',
                description: '256K context, code specialized'
            },
            {
                id: 'deepseek/deepseek-prover-v2',
                name: 'DeepSeek Prover V2 (164K tokens)',
                provider: 'DeepSeek',
                description: '164K context, theorem proving/code'
            },
            {
                id: 'inception/mercury-coder',
                name: 'Mercury Coder (128K tokens)',
                provider: 'Inception',
                description: '128K context, coding focused'
            },
            // ===== REASONING MODELS =====
            {
                id: 'moonshotai/kimi-k2-thinking',
                name: 'Kimi K2 Thinking (262K tokens)',
                provider: 'MoonshotAI',
                description: '262K context, strong reasoning'
            },
            {
                id: 'openai/o3-deep-research',
                name: 'o3 Deep Research (200K tokens)',
                provider: 'OpenAI',
                description: '200K context, deep reasoning'
            },
            {
                id: 'arcee-ai/maestro-reasoning',
                name: 'Maestro Reasoning (131K tokens)',
                provider: 'Arcee AI',
                description: '131K context, reasoning focused'
            },
            {
                id: 'deepseek/deepseek-r1:free',
                name: 'DeepSeek R1 (128K tokens - Free)',
                provider: 'DeepSeek',
                description: '128K context reasoning, free tier'
            },
            {
                id: 'microsoft/phi-4-reasoning-plus',
                name: 'Phi 4 Reasoning Plus (33K tokens)',
                provider: 'Microsoft',
                description: '33K context, efficient reasoning'
            },
            // ===== FAST & EFFICIENT MODELS =====
            {
                id: 'mistralai/mistral-small-3.2-24b-instruct',
                name: 'Mistral Small 3.2 (131K tokens)',
                provider: 'Mistral',
                description: '131K context, fast and efficient'
            },
            {
                id: 'google/gemini-2.5-flash-lite',
                name: 'Gemini 2.5 Flash Lite (1M tokens)',
                provider: 'Google',
                description: '1M context, very cost-effective'
            },
            {
                id: 'mistralai/ministral-8b',
                name: 'Ministral 8B (131K tokens)',
                provider: 'Mistral',
                description: '131K context, lightweight'
            },
            {
                id: 'meta-llama/llama-3.2-3b-instruct:free',
                name: 'Llama 3.2 3B (131K tokens - Free)',
                provider: 'Meta',
                description: '131K context, very fast, free'
            },
            {
                id: 'microsoft/phi-3.5-mini-instruct',
                name: 'Phi 3.5 Mini (33K tokens)',
                provider: 'Microsoft',
                description: '33K context, extremely fast'
            },
            // ===== LATEST & GREATEST =====
            {
                id: 'openai/gpt-5.1-chat',
                name: 'GPT-5.1 Chat (128K tokens)',
                provider: 'OpenAI',
                description: 'Latest GPT-5 chat optimized'
            },
            {
                id: 'anthropic/claude-haiku-4.5',
                name: 'Claude Haiku 4.5 (200K tokens)',
                provider: 'Anthropic',
                description: 'Latest Claude Haiku, 200K context'
            },
            {
                id: 'meta-llama/llama-4-maverick',
                name: 'Llama 4 Maverick (1M tokens)',
                provider: 'Meta',
                description: 'Latest Llama 4, 1M context'
            },
            {
                id: 'deepseek/deepseek-v3.2-speciale',
                name: 'DeepSeek V3.2 Speciale (164K tokens)',
                provider: 'DeepSeek',
                description: 'Special DeepSeek edition'
            },
            {
                id: 'z-ai/glm-4.6',
                name: 'GLM 4.6 (203K tokens)',
                provider: 'Z.AI',
                description: 'Latest GLM, 203K context'
            },
            // ===== COST-EFFECTIVE POWERHOUSES =====
            {
                id: 'prime-intellect/intellect-3',
                name: 'INTELLECT-3 (131K tokens)',
                provider: 'Prime Intellect',
                description: '131K context, very cost-effective'
            },
            {
                id: 'qwen/qwen3-32b',
                name: 'Qwen3 32B (41K tokens)',
                provider: 'Qwen',
                description: '41K context, great value'
            },
            {
                id: 'nvidia/nemotron-nano-9b-v2:free',
                name: 'Nemotron Nano 9B (128K tokens - Free)',
                provider: 'NVIDIA',
                description: '128K context, free tier'
            },
            {
                id: 'ibm-granite/granite-4.0-h-micro',
                name: 'Granite 4.0 Micro (131K tokens)',
                provider: 'IBM',
                description: '131K context, very cheap'
            },
            {
                id: 'liquid/lfm2-8b-a1b',
                name: 'LFM2 8B (33K tokens)',
                provider: 'LiquidAI',
                description: '33K context, excellent price'
            },
            // ===== VISUAL MODELS (if you want multimodal) =====
            {
                id: 'openai/gpt-5-image',
                name: 'GPT-5 Image (400K tokens)',
                provider: 'OpenAI',
                description: '400K context, image understanding'
            },
            {
                id: 'qwen/qwen3-vl-8b-instruct',
                name: 'Qwen3 VL 8B (131K tokens)',
                provider: 'Qwen',
                description: '131K context, vision+language'
            },
            {
                id: 'openai/gpt-4o-audio-preview',
                name: 'GPT-4o Audio (128K tokens)',
                provider: 'OpenAI',
                description: '128K context, audio+language'
            },
            {
                id: 'google/gemini-2.5-flash-image',
                name: 'Gemini 2.5 Flash Image (33K tokens)',
                provider: 'Google',
                description: '33K context, image understanding'
            }
        ];
        openrouterPanel.instance = this;
        this.diffSystem = diffSystem;
        this.loadConfiguration();
        this.loadSaveSetting();
        this.loadChatHistory();
        this.startAutoSave();
    }
    static getInstance() {
        return openrouterPanel.instance;
    }
    // ============================================================================
    // DIFF INTEGRATION METHODS
    // ============================================================================
    async applyDiffFromChat(diff, explanation) {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }
        // Validate diff first
        const validation = this.diffSystem.validateDiff(diff);
        if (!validation.isValid) {
            vscode.window.showErrorMessage(`Invalid diff format:\n${validation.errors.join('\n')}`);
            return;
        }
        // Show preview option
        const choice = await vscode.window.showQuickPick([
            { label: '$(eye) Preview changes', description: 'See what will change before applying' },
            { label: '$(check) Apply directly', description: 'Apply the diff immediately' },
            { label: '$(save) Save to help file', description: 'Save for later review' }
        ], { placeHolder: 'How would you like to proceed with this diff?' });
        if (!choice) {
            return;
        }
        const originalContent = editor.document.getText();
        if (choice.label.includes('Preview')) {
            await this.previewDiff(originalContent, diff, explanation); // Pass explanation here
            return;
        }
        if (choice.label.includes('Save')) {
            const saved = this.diffSystem.saveAISuggestionToHelpFile(editor.document.uri.fsPath, {
                diff,
                explanation,
                model: this.model,
                query: this.getLastUserMessage() || 'AI suggestion'
            });
            if (saved) {
                vscode.window.showInformationMessage('✅ AI suggestion saved to help file');
            }
            else {
                vscode.window.showErrorMessage('Failed to save suggestion');
            }
            return;
        }
        // Apply directly
        const result = this.diffSystem.applyUnifiedDiff(originalContent, diff);
        if (result.success) {
            const edit = new vscode.WorkspaceEdit();
            const entireRange = new vscode.Range(editor.document.positionAt(0), editor.document.positionAt(originalContent.length));
            edit.replace(editor.document.uri, entireRange, result.newContent);
            const applied = await vscode.workspace.applyEdit(edit);
            if (applied) {
                vscode.window.showInformationMessage(`✅ Diff applied! ${result.totalChanges} changes made.`);
                // Store as last suggestion for quick re-apply
                this.lastAISuggestion = {
                    id: Date.now().toString(),
                    timestamp: new Date(),
                    model: this.model,
                    originalQuery: this.getLastUserMessage() || '',
                    diff,
                    explanation,
                    filePath: editor.document.uri.fsPath,
                    applied: true
                };
                this.diffSystem.setLastSuggestion(this.lastAISuggestion);
            }
        }
        else {
            vscode.window.showErrorMessage(`❌ Failed to apply diff:\n${result.errors.join('\n')}`);
        }
    }
    async applyLastSuggestion() {
        if (!this.lastAISuggestion) {
            vscode.window.showInformationMessage('No recent AI suggestion to apply');
            return;
        }
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }
        const confirm = await vscode.window.showQuickPick(['Yes', 'No'], { placeHolder: `Apply "${this.lastAISuggestion.explanation.substring(0, 50)}..."?` });
        if (confirm !== 'Yes') {
            return;
        }
        const originalContent = editor.document.getText();
        const result = this.diffSystem.applyUnifiedDiff(originalContent, this.lastAISuggestion.diff);
        if (result.success) {
            const edit = new vscode.WorkspaceEdit();
            const entireRange = new vscode.Range(editor.document.positionAt(0), editor.document.positionAt(originalContent.length));
            edit.replace(editor.document.uri, entireRange, result.newContent);
            await vscode.workspace.applyEdit(edit);
            vscode.window.showInformationMessage('✅ Last AI suggestion applied!');
        }
    }
    async requestCodeReview() {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }
        const code = editor.document.getText();
        const language = editor.document.languageId;
        const fileName = editor.document.fileName.split('/').pop();
        // Add to chat
        if (this._view) {
            const userMessage = {
                role: 'user',
                content: `Please review this ${language} code from ${fileName}:\n\n${code}`,
                timestamp: new Date()
            };
            this.chatHistory.push(userMessage);
            this.sendHistoryToWebview();
            // Auto-send to AI
            await this.handleChat(`Review this ${language} code and suggest improvements`, code);
        }
    }
    async previewDiff(original, diff, explanation) {
        try {
            const preview = this.diffSystem.previewDiff(original, diff);
            // Create a diff view
            const panel = vscode.window.createWebviewPanel('diffPreview', 'Diff Preview', vscode.ViewColumn.Beside, { enableScripts: true });
            let html = `<html><body style="font-family: var(--vscode-font-family); padding: 20px;">
                <h2>Diff Preview</h2>
                ${explanation ? `<p style="color: var(--secondary); margin-bottom: 16px;">${explanation}</p>` : ''}
                <div style="display: flex; gap: 20px;">
                    <div style="flex: 1; border-right: 1px solid #ccc; padding-right: 20px;">
                        <h3>Original (${preview.originalLines.length} lines)</h3>
                        <pre style="background: #f5f5f5; padding: 10px; border-radius: 5px; max-height: 400px; overflow: auto;">`;
            preview.originalLines.forEach((line, i) => {
                const change = preview.changes.find(c => c.line === i + 1);
                if (change) {
                    html += `<span style="background: #ffe0e0;">${line}</span>\n`;
                }
                else {
                    html += `${line}\n`;
                }
            });
            html += `</pre></div>
                    <div style="flex: 1;">
                        <h3>New (${preview.newLines.length} lines)</h3>
                        <pre style="background: #f5f5f5; padding: 10px; border-radius: 5px; max-height: 400px; overflow: auto;">`;
            preview.newLines.forEach((line, i) => {
                const change = preview.changes.find(c => c.line === i + 1);
                if (change) {
                    html += `<span style="background: #e0ffe0;">${line}</span>\n`;
                }
                else {
                    html += `${line}\n`;
                }
            });
            html += `</pre>
                    </div>
                </div>
                <div style="margin-top: 20px;">
                    <h3>Changes (${preview.changes.length})</h3>
                    <ul>`;
            preview.changes.forEach(change => {
                html += `<li>Line ${change.line}: ${change.type} - ${change.content.substring(0, 50)}...</li>`;
            });
            html += `</ul>
                </div>
                <div style="margin-top: 20px;" id="previewActions">
                    <!-- Buttons will be added programmatically -->
                </div>
            </body></html>`;
            panel.webview.html = html;
            panel.webview.onDidReceiveMessage(async (message) => {
                if (message.command === 'applyDiffFromPreview') {
                    const editor = vscode.window.activeTextEditor;
                    if (editor) {
                        const originalContent = editor.document.getText();
                        const result = this.diffSystem.applyUnifiedDiff(originalContent, diff);
                        if (result.success) {
                            const edit = new vscode.WorkspaceEdit();
                            const entireRange = new vscode.Range(editor.document.positionAt(0), editor.document.positionAt(originalContent.length));
                            edit.replace(editor.document.uri, entireRange, result.newContent);
                            await vscode.workspace.applyEdit(edit);
                            vscode.window.showInformationMessage('✅ Diff applied from preview!');
                            panel.dispose();
                        }
                    }
                }
            }, undefined, this._disposables);
            // Inject JavaScript to create buttons programmatically
            setTimeout(() => {
                panel.webview.postMessage({
                    command: 'setupPreviewModalButtons',
                    diff: diff,
                    explanation: explanation || "Preview of AI suggested changes"
                });
            }, 100);
        }
        catch (error) {
            vscode.window.showErrorMessage(`Failed to preview diff: ${error}`);
        }
    }
    getLastUserMessage() {
        for (let i = this.chatHistory.length - 1; i >= 0; i--) {
            if (this.chatHistory[i].role === 'user') {
                return this.chatHistory[i].content;
            }
        }
        return undefined;
    }
    // ============================================================================
    // CHAT AND WEBVIEW METHODS (from original, with diff enhancements)
    // ============================================================================
    sendHistoryToWebview() {
        if (!this._view || !this.isInitialized) {
            setTimeout(() => this.sendHistoryToWebview(), 100);
            return;
        }
        console.log('Sending chat history to webview:', this.chatHistory.length, 'messages');
        this._view.webview.postMessage({
            command: 'chatHistoryLoaded',
            history: this.chatHistory.map(msg => ({
                role: msg.role,
                content: msg.content,
                timestamp: msg.timestamp.toISOString(),
                model: msg.role === 'assistant' ? msg.model || this.model : undefined,
                containsDiff: msg.containsDiff,
                diff: msg.diff,
                explanation: msg.explanation
            }))
        });
    }
    async saveChatHistory() {
        if (!this.saveChatHistoryEnabled) {
            return;
        }
        try {
            const serializableHistory = this.chatHistory.map(msg => ({
                role: msg.role,
                content: msg.content,
                timestamp: msg.timestamp.toISOString(),
                model: msg.model,
                containsDiff: msg.containsDiff,
                diff: msg.diff,
                explanation: msg.explanation
            }));
            await this.context.globalState.update(this.CHAT_HISTORY_KEY, serializableHistory);
        }
        catch (error) {
            console.error('Failed to save chat history:', error);
        }
    }
    loadChatHistory() {
        try {
            const saved = this.context.globalState.get(this.CHAT_HISTORY_KEY);
            if (saved && Array.isArray(saved)) {
                this.chatHistory = saved.map(msg => ({
                    role: msg.role,
                    content: msg.content,
                    timestamp: new Date(msg.timestamp),
                    model: msg.model,
                    containsDiff: msg.containsDiff,
                    diff: msg.diff,
                    explanation: msg.explanation
                }));
                console.log('Chat history loaded:', this.chatHistory.length, 'messages');
            }
            else {
                this.chatHistory = [];
            }
        }
        catch (error) {
            console.error('Failed to load chat history:', error);
            this.chatHistory = [];
        }
    }
    loadSaveSetting() {
        try {
            const savedSetting = this.context.globalState.get(this.SAVE_SETTING_KEY);
            this.saveChatHistoryEnabled = savedSetting === undefined ? true : savedSetting;
        }
        catch (error) {
            console.error('Failed to load save setting:', error);
            this.saveChatHistoryEnabled = true;
        }
    }
    startAutoSave() {
        setInterval(async () => {
            if (this.chatHistory.length > 0) {
                try {
                    await this.saveChatHistory();
                }
                catch (error) {
                    console.error('Auto-save failed:', error);
                }
            }
        }, 30000);
    }
    updateSaveSetting(enabled) {
        this.saveChatHistoryEnabled = enabled;
        this.context.globalState.update(this.SAVE_SETTING_KEY, enabled);
        if (!enabled) {
            this.context.globalState.update(this.CHAT_HISTORY_KEY, undefined);
        }
    }
    loadConfiguration() {
        console.log('🔧 [loadConfiguration] START - Loading configuration...');
        try {
            const config = vscode.workspace.getConfiguration('openrouter');
            console.log('📝 [loadConfiguration] Configuration section obtained');
            // Log what we're reading
            const apiKey = config.get('apiKey', '');
            const model = config.get('model', 'deepseek/deepseek-r1-0528-qwen3-8b');
            const httpReferer = config.get('httpReferer', 'https://github.com');
            const xTitle = config.get('xTitle', 'OpenRouter Chat VS Code Extension');
            const baseURL = config.get('baseURL', 'https://openrouter.ai/api/v1');
            console.log('📊 [loadConfiguration] Values read from config:');
            console.log(`   - apiKey: ${apiKey ? '****' + apiKey.substring(apiKey.length - 4) : '(empty)'}`);
            console.log(`   - model: ${model}`);
            console.log(`   - httpReferer: ${httpReferer}`);
            console.log(`   - xTitle: ${xTitle}`);
            console.log(`   - baseURL: ${baseURL}`);
            this.apiKey = apiKey;
            this.model = model;
            this.httpReferer = httpReferer;
            this.xTitle = xTitle;
            this.baseURL = baseURL;
            if (this.apiKey) {
                console.log('🤖 [loadConfiguration] Initializing OpenAI with loaded API key...');
                this.initializeOpenAI();
            }
            else {
                console.log('⚠️ [loadConfiguration] No API key found in configuration');
            }
            console.log('✅ [loadConfiguration] COMPLETE - Configuration loaded');
        }
        catch (error) {
            console.error('❌ [loadConfiguration] ERROR - Failed to load configuration:', error);
            if (error instanceof Error) {
                console.error('📋 [loadConfiguration] Error details:', error.message);
            }
            else {
                console.error('📋 [loadConfiguration] Unknown error type');
            }
            // Use defaults
            this.apiKey = '';
            this.model = 'deepseek/deepseek-r1-0528-qwen3-8b';
            this.httpReferer = 'https://github.com';
            this.xTitle = 'OpenRouter Chat VS Code Extension';
            this.baseURL = 'https://openrouter.ai/api/v1';
            console.log('🔄 [loadConfiguration] Using default configuration due to error');
        }
    }
    async saveConfiguration(config) {
        console.log('🔧 [saveConfiguration] START - Saving configuration...');
        console.log('📋 [saveConfiguration] Config received:', {
            apiKey: config.apiKey === null ? '(keep existing)' :
                (config.apiKey ? `${config.apiKey.substring(0, 4)}...${config.apiKey.substring(config.apiKey.length - 4)}` : '(empty)'),
            model: config.model,
            httpReferer: config.httpReferer,
            xTitle: config.xTitle,
            baseURL: config.baseURL,
            apiKeyIsNull: config.apiKey === null
        });
        try {
            console.log('📝 [saveConfiguration] Getting configuration section...');
            const configSection = vscode.workspace.getConfiguration('openrouter');
            // Log current config before update
            console.log('📊 [saveConfiguration] Current config values:');
            const currentApiKey = configSection.get('apiKey', '');
            const currentModel = configSection.get('model', '');
            console.log(`   - apiKey: ${currentApiKey ? '****' + currentApiKey.substring(currentApiKey.length - 4) : '(empty)'}`);
            console.log(`   - model: ${currentModel}`);
            // CRITICAL FIX: Only update API key if a new one was provided
            if (config.apiKey !== null) {
                console.log('💾 [saveConfiguration] Updating API key (new value provided)...');
                await configSection.update('apiKey', config.apiKey, vscode.ConfigurationTarget.Global);
                console.log('✅ [saveConfiguration] apiKey saved successfully');
                // Update local variable
                this.apiKey = config.apiKey || '';
            }
            else {
                console.log('🔒 [saveConfiguration] Keeping existing API key');
                // Keep existing API key
                this.apiKey = currentApiKey;
            }
            console.log('💾 [saveConfiguration] Attempting to save model...');
            await configSection.update('model', config.model, vscode.ConfigurationTarget.Global);
            console.log('✅ [saveConfiguration] model saved successfully');
            // Update local model
            this.model = config.model;
            if (config.httpReferer) {
                console.log('💾 [saveConfiguration] Attempting to save httpReferer...');
                await configSection.update('httpReferer', config.httpReferer, vscode.ConfigurationTarget.Global);
                console.log('✅ [saveConfiguration] httpReferer saved successfully');
                this.httpReferer = config.httpReferer;
            }
            if (config.xTitle) {
                console.log('💾 [saveConfiguration] Attempting to save xTitle...');
                await configSection.update('xTitle', config.xTitle, vscode.ConfigurationTarget.Global);
                console.log('✅ [saveConfiguration] xTitle saved successfully');
                this.xTitle = config.xTitle;
            }
            if (config.baseURL) {
                console.log('💾 [saveConfiguration] Attempting to save baseURL...');
                await configSection.update('baseURL', config.baseURL, vscode.ConfigurationTarget.Global);
                console.log('✅ [saveConfiguration] baseURL saved successfully');
                this.baseURL = config.baseURL;
            }
            console.log('📊 [saveConfiguration] Final local variables:');
            console.log(`   - this.apiKey: ${this.apiKey ? '****' + this.apiKey.substring(this.apiKey.length - 4) : '(empty)'}`);
            console.log(`   - this.model: ${this.model}`);
            console.log(`   - this.httpReferer: ${this.httpReferer}`);
            console.log(`   - this.xTitle: ${this.xTitle}`);
            console.log(`   - this.baseURL: ${this.baseURL}`);
            // Re-initialize OpenAI client
            console.log('🤖 [saveConfiguration] Initializing OpenAI client...');
            this.initializeOpenAI();
            console.log('✅ [saveConfiguration] OpenAI client initialized');
            if (this._view) {
                console.log('📤 [saveConfiguration] Sending success message to webview...');
                this._view.webview.postMessage({
                    command: 'configurationSaved',
                    success: true,
                    apiKey: this.apiKey,
                    model: this.model,
                    hasApiKey: !!this.apiKey
                });
                console.log('✅ [saveConfiguration] Success message sent to webview');
            }
            console.log('🎉 [saveConfiguration] Showing success notification...');
            vscode.window.showInformationMessage('AI Assistant configuration saved!');
            console.log('✅ [saveConfiguration] COMPLETE - Configuration saved successfully!');
        }
        catch (error) {
            console.error('❌ [saveConfiguration] ERROR - Failed to save configuration:', error);
            // Type guard for error
            if (error instanceof Error) {
                console.error('📋 [saveConfiguration] Error details:', {
                    name: error.name,
                    message: error.message,
                    stack: error.stack,
                    constructor: error.constructor?.name
                });
            }
            else {
                console.error('📋 [saveConfiguration] Unknown error type:', error);
            }
            // Provide more specific error handling
            let errorMessage = `Failed to save configuration: ${error}`;
            // Check for specific error conditions
            if (error instanceof Error) {
                console.log('🔍 [saveConfiguration] Error is instanceof Error');
                if (error.message.includes('Unable to write into user settings')) {
                    console.log('🔍 [saveConfiguration] Detected: Unable to write into user settings');
                    errorMessage = 'Unable to save configuration. Please open your VS Code settings (File > Preferences > Settings) to fix any errors in the settings file.';
                    // Offer to open settings
                    vscode.window.showErrorMessage(errorMessage, 'Open Settings').then(selection => {
                        if (selection === 'Open Settings') {
                            console.log('🔗 [saveConfiguration] User clicked "Open Settings"');
                            vscode.commands.executeCommand('workbench.action.openSettings');
                        }
                        else {
                            console.log('🔗 [saveConfiguration] User cancelled opening settings');
                        }
                    });
                }
                else if (error.message.includes('permission denied')) {
                    console.log('🔍 [saveConfiguration] Detected: Permission denied');
                    errorMessage = 'Permission denied when trying to save configuration. Please check file permissions for your VS Code settings.';
                }
                else if (error.message.includes('ENOENT')) {
                    console.log('🔍 [saveConfiguration] Detected: File not found (ENOENT)');
                    errorMessage = 'Settings file not found. VS Code settings directory might be corrupted.';
                }
                else if (error.message.includes('JSON')) {
                    console.log('🔍 [saveConfiguration] Detected: JSON parsing error');
                    errorMessage = 'JSON error in settings file. The settings file might have syntax errors.';
                }
            }
            else {
                console.log('🔍 [saveConfiguration] Error is NOT instanceof Error');
            }
            console.log('📤 [saveConfiguration] Sending error to webview:', errorMessage);
            if (this._view) {
                this._view.webview.postMessage({
                    command: 'error',
                    message: errorMessage
                });
            }
            // Try to save to global state as fallback
            console.log('🔄 [saveConfiguration] Attempting fallback to global state...');
            try {
                const errorMessageForFallback = error instanceof Error ? error.message : String(error);
                await this.context.globalState.update('openrouter_config_fallback', {
                    apiKey: config.apiKey,
                    model: config.model,
                    httpReferer: config.httpReferer || 'https://github.com',
                    xTitle: config.xTitle || 'OpenRouter Chat VS Code Extension',
                    baseURL: config.baseURL || 'https://openrouter.ai/api/v1',
                    savedAt: new Date().toISOString(),
                    error: errorMessageForFallback
                });
                console.log('✅ [saveConfiguration] Saved to global state fallback');
                // Still update local variables so extension works for this session
                this.apiKey = config.apiKey || '';
                this.model = config.model;
                this.initializeOpenAI();
                vscode.window.showInformationMessage('Configuration saved locally (VS Code settings file issue)');
            }
            catch (fallbackError) {
                console.error('❌ [saveConfiguration] Fallback also failed:', fallbackError);
            }
        }
    }
    initializeOpenAI() {
        if (!this.apiKey) {
            this.openai = null;
            return;
        }
        try {
            this.openai = new openai_1.default({
                apiKey: this.apiKey,
                baseURL: this.baseURL,
                dangerouslyAllowBrowser: true
            });
            console.log('OpenAI client initialized for OpenRouter');
        }
        catch (error) {
            console.error('Failed to initialize OpenAI client:', error);
            this.openai = null;
        }
    }
    async saveOnDeactivate() {
        await this.saveChatHistory();
    }
    clearHistory() {
        this.chatHistory = [];
        this.context.globalState.update(this.CHAT_HISTORY_KEY, undefined);
        if (this._view) {
            this._view.webview.postMessage({
                command: 'historyCleared'
            });
        }
        vscode.window.showInformationMessage('Chat history cleared');
    }
    showSettings() {
        if (this._view) {
            this._view.show?.(true);
            this._view.webview.postMessage({
                command: 'showSettings'
            });
        }
    }
    // ============================================================================
    // WEBVIEW PROVIDER IMPLEMENTATION
    // ============================================================================
    resolveWebviewView(webviewView, _context, _token) {
        this._view = webviewView;
        webviewView.webview.options = {
            enableScripts: true,
            localResourceRoots: [this.context.extensionUri]
        };
        webviewView.webview.html = this.getWebviewContent(webviewView.webview);
        this.setupMessageHandlers(webviewView);
        this.isInitialized = true;
        setTimeout(() => this.sendHistoryToWebview(), 100);
    }
    setupMessageHandlers(webviewView) {
        webviewView.webview.onDidReceiveMessage(async (message) => {
            try {
                console.log('Received message:', message.command);
                switch (message.command) {
                    case 'chat':
                        await this.handleChat(message.content, message.code);
                        break;
                    case 'saveConfiguration':
                        this.saveConfiguration({
                            apiKey: message.apiKey,
                            model: message.model,
                            httpReferer: message.httpReferer,
                            xTitle: message.xTitle,
                            baseURL: message.baseURL
                        });
                        break;
                    case 'getAvailableModels':
                        webviewView.webview.postMessage({
                            command: 'availableModels',
                            models: this.availableModels
                        });
                        break;
                    case 'getActiveCode':
                        await this.handleGetActiveCode();
                        break;
                    case 'getChatHistory':
                        this.sendHistoryToWebview();
                        break;
                    case 'saveDiff': // NEW: Save diff to help file
                        await this.saveDiffToHelpFile(message.diff, message.explanation);
                        break;
                    case 'applyDiff': // NEW: Apply diff from chat
                        await this.applyDiffFromChat(message.diff, message.explanation);
                        break;
                    case 'validateDiff': // NEW: Validate diff
                        const validation = this.diffSystem.validateDiff(message.diff);
                        webviewView.webview.postMessage({
                            command: 'diffValidation',
                            isValid: validation.isValid,
                            errors: validation.errors,
                            warnings: validation.warnings
                        });
                        break;
                    case 'extractDiff': // NEW: Extract diff from text
                        const extracted = this.diffSystem.extractDiffFromAIResponse(message.text);
                        webviewView.webview.postMessage({
                            command: 'diffExtracted',
                            diff: extracted.diff,
                            explanation: extracted.explanation,
                            found: !!extracted.diff
                        });
                        break;
                    case 'applyGitPatch':
                        const workspaceFolders = vscode.workspace.workspaceFolders;
                        if (workspaceFolders && workspaceFolders.length > 0) {
                            const fullPath = path.join(workspaceFolders[0].uri.fsPath, message.patchPath);
                            const result = await this.diffSystem?.applyPatchFromFile(fullPath);
                            webviewView.webview.postMessage({
                                command: 'gitPatchApplied',
                                success: result?.success || false,
                                error: result?.error || ''
                            });
                        }
                        break;
                    case 'copyToClipboard':
                        await vscode.env.clipboard.writeText(message.text);
                        webviewView.webview.postMessage({
                            command: 'clipboardCopied'
                        });
                        break;
                    case 'addComment':
                        await this.addCommentToActiveFile(message.comment, message.line);
                        break;
                    case 'stopRequest':
                        this.abortController?.abort();
                        break;
                    case 'clearHistory':
                        this.clearHistory();
                        break;
                    case 'getCurrentConfig':
                        webviewView.webview.postMessage({
                            command: 'currentConfig',
                            apiKey: this.apiKey ? this.apiKey.substring(0, 4) + '...' + this.apiKey.substring(this.apiKey.length - 4) : '',
                            model: this.model,
                            httpReferer: this.httpReferer,
                            xTitle: this.xTitle,
                            baseURL: this.baseURL,
                            hasApiKey: !!this.apiKey,
                            saveChatHistory: this.saveChatHistoryEnabled
                        });
                        break;
                    case 'updateSaveSetting':
                        this.updateSaveSetting(message.enabled);
                        webviewView.webview.postMessage({
                            command: 'saveSettingUpdated',
                            enabled: message.enabled
                        });
                        break;
                    case 'requestCodeReview':
                        await this.requestCodeReview();
                        break;
                    case 'applyLastSuggestion':
                        await this.applyLastSuggestion();
                        break;
                }
            }
            catch (error) {
                console.error('Error handling message:', error);
                webviewView.webview.postMessage({
                    command: 'error',
                    message: `Failed: ${error}`
                });
            }
        }, null, this._disposables);
    }
    async saveDiffToHelpFile(diff, explanation) {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }
        const saved = this.diffSystem.saveAISuggestionToHelpFile(editor.document.uri.fsPath, {
            diff,
            explanation,
            model: this.model,
            query: this.getLastUserMessage() || 'AI suggestion'
        });
        if (saved) {
            vscode.window.showInformationMessage('✅ AI suggestion saved to help file');
            if (this._view) {
                this._view.webview.postMessage({
                    command: 'diffSaved',
                    success: true
                });
            }
        }
        else {
            vscode.window.showErrorMessage('Failed to save suggestion');
            if (this._view) {
                this._view.webview.postMessage({
                    command: 'diffSaved',
                    success: false,
                    message: 'Failed to save suggestion'
                });
            }
        }
    }
    async handleChat(content, code) {
        if (!this._view) {
            console.error('No webview view available');
            return;
        }
        // Check if API key is configured
        if (!this.apiKey || !this.openai) {
            console.log('API key not configured, showing settings');
            this._view.webview.postMessage({
                command: 'apiKeyRequired'
            });
            return;
        }
        // Add user message to history
        const userMessage = {
            role: 'user',
            content: code ? `${content}\n\nCode context:\n${code}` : content,
            timestamp: new Date()
        };
        this.chatHistory.push(userMessage);
        // Show loading state
        this._view.webview.postMessage({
            command: 'loading',
            loading: true
        });
        try {
            this.abortController = new AbortController();
            // Prepare messages for API
            const messages = [
                {
                    role: 'system',
                    content: `You are an AI coding assistant. When suggesting code changes, provide them as unified diffs with proper format.
                    
                    For code changes, ALWAYS provide COMPLETE unified diffs:
                    \`\`\`diff
                    --- a/filename.ext
                    +++ b/filename.ext
                    @@ -line,count +line,count @@
                    -old line
                    +new line
                    \`\`\`
                    
                    Include explanations before the diff. Never leave diffs incomplete.`
                },
                ...this.chatHistory.map(msg => ({
                    role: msg.role,
                    content: msg.content
                }))
            ];
            console.log('Sending request to model:', this.model);
            const response = await this.openai.chat.completions.create({
                model: this.model,
                messages: messages,
                max_tokens: 8000,
                temperature: 0.7,
                stream: true
            }, {
                signal: this.abortController.signal,
                headers: {
                    'HTTP-Referer': this.httpReferer,
                    'X-Title': this.xTitle,
                    // Request higher limits if available
                    'X-Max-Tokens': '16000',
                    'X-Token-Limit': '200000' // Request higher limit
                },
                timeout: 120000
            });
            let fullResponse = '';
            let accumulatedChunks = [];
            let lastSendTime = Date.now();
            const CHUNK_FLUSH_INTERVAL = 100;
            for await (const chunk of response) {
                const now = Date.now();
                if (chunk.choices[0]?.delta?.content) {
                    const content = chunk.choices[0].delta.content;
                    fullResponse += content;
                    accumulatedChunks.push(content);
                    if (accumulatedChunks.length >= 5 || (now - lastSendTime) >= CHUNK_FLUSH_INTERVAL) {
                        if (accumulatedChunks.length > 0) {
                            const chunkToSend = accumulatedChunks.join('');
                            this._view.webview.postMessage({
                                command: 'streamChunk',
                                content: chunkToSend
                            });
                            accumulatedChunks = [];
                            lastSendTime = now;
                        }
                    }
                }
                if (chunk.choices[0]?.finish_reason) {
                    if (chunk.choices[0].finish_reason === 'length') {
                        const warning = '\n\n[Response truncated due to token limit. Ask for a shorter response or break into parts.]';
                        fullResponse += warning;
                        this._view.webview.postMessage({
                            command: 'streamChunk',
                            content: warning
                        });
                    }
                    break;
                }
            }
            // Send any remaining chunks
            if (accumulatedChunks.length > 0) {
                this._view.webview.postMessage({
                    command: 'streamChunk',
                    content: accumulatedChunks.join('')
                });
            }
            // Check if response contains a diff
            const extracted = this.diffSystem.extractDiffFromAIResponse(fullResponse);
            const containsDiff = !!extracted.diff;
            // Add assistant response to history
            const assistantMessage = {
                role: 'assistant',
                content: fullResponse,
                timestamp: new Date(),
                model: this.model,
                containsDiff: containsDiff,
                diff: containsDiff ? extracted.diff : undefined,
                explanation: containsDiff ? extracted.explanation : undefined,
                patchFile: undefined, // Initialize
                gitCommand: undefined // Initialize
            };
            this.chatHistory.push(assistantMessage);
            // Save chat history
            this.saveChatHistory();
            // AUTO-SAVE .diff FILE if contains diff
            if (containsDiff && extracted.diff) {
                const editor = vscode.window.activeTextEditor;
                if (editor) {
                    const filePath = editor.document.uri.fsPath;
                    const fileName = path.basename(filePath);
                    // Fix the diff with proper file paths using existing methods
                    const cleanedDiff = this.diffSystem.extractDiffFromAIResponse(fullResponse).diff || '';
                    const gitCompatibleDiff = this.diffSystem.makeGitCompatible(cleanedDiff, fileName);
                    const validation = this.diffSystem.validateDiff(gitCompatibleDiff);
                    if (validation.isValid && gitCompatibleDiff) {
                        // Save as git-compatible patch
                        const saveResult = this.diffSystem.saveAsGitPatch(gitCompatibleDiff, filePath, extracted.explanation || 'AI suggested change', this.model, content, extracted.explanation || '');
                        if (saveResult.success) {
                            // Show notification with git command
                            const workspaceFolders = vscode.workspace.workspaceFolders;
                            const workspaceRoot = workspaceFolders?.[0]?.uri.fsPath || '';
                            const relativePatch = path.relative(workspaceRoot, saveResult.patchPath).replace(/\\/g, '/');
                            vscode.window.showInformationMessage(`✅ Patch saved: ${relativePatch}`, 'Copy Git Command', 'Open Folder', 'Apply Now').then(async (selection) => {
                                if (selection === 'Copy Git Command') {
                                    await vscode.env.clipboard.writeText(saveResult.gitCommand);
                                    vscode.window.showInformationMessage('Git command copied to clipboard!');
                                }
                                else if (selection === 'Open Folder') {
                                    const uri = vscode.Uri.file(path.dirname(saveResult.patchPath));
                                    vscode.commands.executeCommand('revealFileInOS', uri);
                                }
                                else if (selection === 'Apply Now') {
                                    const result = await this.diffSystem.applyGitPatch(saveResult.patchPath);
                                    if (result.success) {
                                        vscode.window.showInformationMessage('✅ Patch applied successfully!');
                                        // Reload the file to show changes
                                        vscode.commands.executeCommand('workbench.action.files.revert');
                                    }
                                    else {
                                        vscode.window.showErrorMessage(`❌ Failed to apply patch: ${result.error}`);
                                    }
                                }
                            });
                            // Update message with patch info
                            assistantMessage.patchFile = saveResult.patchPath;
                            assistantMessage.gitCommand = saveResult.gitCommand;
                        }
                    }
                }
            }
            // Store as last suggestion if it contains a diff
            if (containsDiff && extracted.diff) {
                const editor = vscode.window.activeTextEditor;
                this.lastAISuggestion = {
                    id: Date.now().toString(),
                    timestamp: new Date(),
                    model: this.model,
                    originalQuery: content,
                    diff: extracted.diff,
                    explanation: extracted.explanation || 'AI suggested change',
                    filePath: editor?.document.uri.fsPath || '',
                    applied: false
                };
                this.diffSystem.setLastSuggestion(this.lastAISuggestion);
            }
            // Send completion
            this._view.webview.postMessage({
                command: 'chatComplete',
                content: fullResponse,
                timestamp: assistantMessage.timestamp.toISOString(),
                model: this.model,
                containsDiff: containsDiff,
                diff: containsDiff ? extracted.diff : undefined,
                explanation: containsDiff ? extracted.explanation : undefined
            });
        }
        catch (error) {
            if (error.name === 'AbortError') {
                console.log('Request aborted by user');
                return;
            }
            console.error('Chat error:', error);
            let errorMessage = `Chat failed: ${error.message}`;
            if (error.message?.includes('timeout')) {
                errorMessage = 'Request timeout. The response might be too long.';
            }
            this._view.webview.postMessage({
                command: 'error',
                message: errorMessage
            });
            // Remove the last user message since it failed
            this.chatHistory.pop();
        }
        finally {
            this.abortController = null;
            this._view.webview.postMessage({
                command: 'loading',
                loading: false
            });
        }
    }
    async handleGetActiveCode() {
        if (!this._view)
            return;
        const editor = vscode.window.activeTextEditor;
        if (editor) {
            const code = editor.document.getText();
            const language = editor.document.languageId;
            const fileName = editor.document.fileName.split('/').pop();
            this._view.webview.postMessage({
                command: 'activeCode',
                code: code,
                language: language,
                fileName: fileName
            });
        }
        else {
            this._view.webview.postMessage({
                command: 'error',
                message: 'No active editor found'
            });
        }
    }
    async addCommentToActiveFile(comment, lineNumber) {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }
        try {
            const edit = new vscode.WorkspaceEdit();
            const document = editor.document;
            const language = editor.document.languageId;
            let commentPrefix = '// ';
            if (language === 'python')
                commentPrefix = '# ';
            else if (language === 'html' || language === 'xml')
                commentPrefix = '<!-- ';
            else if (language === 'css')
                commentPrefix = '/* ';
            const commentText = `${commentPrefix}${comment}${language === 'css' ? ' */' : language === 'html' || language === 'xml' ? ' -->' : ''}\n`;
            let position;
            if (lineNumber !== undefined) {
                position = new vscode.Position(lineNumber, 0);
            }
            else {
                position = editor.selection.active;
            }
            edit.insert(document.uri, position, commentText);
            await vscode.workspace.applyEdit(edit);
            vscode.window.showInformationMessage('Comment added');
        }
        catch (error) {
            vscode.window.showErrorMessage(`Failed to add comment: ${error}`);
        }
    }
    getWebviewContent(webview) {
        const nonce = this.getNonce();
        const cspSource = webview.cspSource;
        // FIXED: Properly escaped template string
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" 
          content="default-src 'none'; style-src ${cspSource} 'unsafe-inline'; script-src 'nonce-${nonce}';">
    <title>OpenRouter Chat</title>
    <style>
        /* ALL CSS from original webview PLUS diff-specific styles */
        :root {
            --vscode-font-family: var(--vscode-font-family, 'Segoe UI', Tahoma, sans-serif);
            --background: var(--vscode-editor-background);
            --foreground: var(--vscode-editor-foreground);
            --input-background: var(--vscode-input-background);
            --input-foreground: var(--vscode-input-foreground);
            --button-background: var(--vscode-button-background);
            --button-foreground: var(--vscode-button-foreground);
            --border: var(--vscode-input-border);
            --secondary: var(--vscode-descriptionForeground);
            --accent: #6b46c1;
            --success: #10b981;
            --warning: #f59e0b;
            --error: #dc3545;
        }
        
        body {
            font-family: var(--vscode-font-family);
            background: var(--background);
            color: var(--foreground);
            margin: 0;
            padding: 8px;
            height: calc(100vh - 16px);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            overflow-y: auto;
        }
        
        .settings-panel {
            background: var(--input-background);
            border: 1px solid var(--border);
            border-radius: 4px;
            padding: 16px;
            margin-bottom: 12px;
            max-height: 300px;
            overflow-y: auto;
            transition: all 0.3s ease;
            display: none;
        }
        
        .settings-panel.visible {
            display: block;
        }
        
        .settings-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
        }
        
        .settings-header h3 {
            margin: 0;
            color: var(--accent);
        }
        
        .settings-input {
            width: 100%;
            box-sizing: border-box;
            margin-bottom: 8px;
            background: var(--input-background);
            color: var(--input-foreground);
            border: 1px solid var(--border);
            border-radius: 2px;
            padding: 6px 8px;
            font-family: var(--vscode-font-family);
        }
        
        .settings-input:focus {
            outline: 2px solid var(--accent);
            border-color: var(--accent);
        }
        
        .settings-input-group {
            margin-bottom: 12px;
        }
        
        .settings-label {
            display: block;
            margin-bottom: 4px;
            font-size: 0.9em;
            color: var(--secondary);
        }
        
        .settings-hint {
            font-size: 0.8em;
            color: var(--secondary);
            margin-top: 4px;
            margin-bottom: 8px;
        }
        
        .chat-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        
        .chat-history {
            flex: 1;
            overflow-y: auto;
            padding: 8px;
            margin-bottom: 8px;
            background: var(--input-background);
            border-radius: 4px;
            border: 1px solid var(--border);
        }
        
        .message {
            margin-bottom: 12px;
            padding: 8px;
            border-radius: 4px;
            max-width: 85%;
        }
        
        .user-message {
            background: rgba(107, 70, 193, 0.1);
            margin-left: auto;
            border: 1px solid rgba(107, 70, 193, 0.3);
        }
        
        .assistant-message {
            background: rgba(96, 125, 139, 0.1);
            margin-right: auto;
            border: 1px solid rgba(96, 125, 139, 0.3);
        }
        
        .message-header {
            font-size: 0.8em;
            color: var(--secondary);
            margin-bottom: 4px;
            display: flex;
            justify-content: space-between;
        }
        
        .message-model {
            color: var(--accent);
            font-weight: bold;
        }
        
        .message-content {
            white-space: pre-wrap;
            word-wrap: break-word;
            line-height: 1.4;
        }
        
        .input-area {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        
        textarea {
            width: 100%;
            min-height: 60px;
            max-height: 150px;
            resize: vertical;
            background: var(--input-background);
            color: var(--input-foreground);
            border: 1px solid var(--border);
            border-radius: 2px;
            padding: 8px;
            font-family: var(--vscode-font-family);
            box-sizing: border-box;
        }
        
        .button-row {
            display: flex;
            gap: 8px;
            align-items: center;
        }
        
        button {
            background: var(--button-background);
            color: var(--button-foreground);
            border: none;
            border-radius: 2px;
            padding: 6px 12px;
            cursor: pointer;
            font-family: var(--vscode-font-family);
            transition: all 0.2s ease;
        }
        
        button:hover {
            opacity: 0.9;
            transform: translateY(-1px);
        }
        
        button:active {
            transform: translateY(0);
        }
        
        button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
        }
        
        .secondary-btn {
            background: transparent;
            border: 1px solid var(--border);
        }
        
        .accent-btn {
            background: var(--accent);
            color: white;
        }
        
        .success-btn {
            background: var(--success);
            color: white;
        }
        
        .stop-btn {
            background: #dc3545;
            color: white;
            margin-left: auto;
            display: none;
        }
        
        .loading {
            display: none;
            align-items: center;
            gap: 8px;
            color: var(--secondary);
            font-size: 0.9em;
            padding: 8px;
        }
        
        .loading.active {
            display: flex;
        }
        
        .loading::after {
            content: '';
            width: 12px;
            height: 12px;
            border: 2px solid var(--accent);
            border-top-color: transparent;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        /* Add these styles to the existing CSS section */
        .loading-timer {
            font-size: 0.8em;
            color: var(--secondary);
            margin-left: 2px;
            text-align: left;
        }


        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        .error {
            color: #dc3545;
            background: rgba(220, 53, 69, 0.1);
            border: 1px solid rgba(220, 53, 69, 0.3);
            border-radius: 4px;
            padding: 8px;
            margin-bottom: 8px;
            display: none;
        }
        
        .error.visible {
            display: block;
        }
        
        .success {
            color: var(--success);
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.3);
            border-radius: 4px;
            padding: 8px;
            margin-bottom: 8px;
            display: none;
        }
        
        .success.visible {
            display: block;
        }
        
        .action-buttons {
            display: flex;
            gap: 4px;
            margin-top: 8px;
        }
        
        .action-btn {
            font-size: 0.8em;
            padding: 2px 6px;
        }
        
        .model-info {
            font-size: 0.8em;
            color: var(--secondary);
            margin-top: 4px;
        }
        
        .model-provider {
            color: var(--accent);
            font-weight: bold;
        }
        
        .current-model {
            padding: 4px 8px;
            background: rgba(107, 70, 193, 0.1);
            border-radius: 4px;
            font-size: 0.9em;
            margin-top: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .toggle-settings {
            background: transparent;
            border: none;
            color: var(--secondary);
            cursor: pointer;
            font-size: 0.9em;
            padding: 2px 6px;
        }
        
        .toggle-settings:hover {
            color: var(--accent);
        }
        
        .api-warning {
            background: rgba(255, 193, 7, 0.1);
            border: 1px solid rgba(255, 193, 7, 0.3);
            border-radius: 4px;
            padding: 8px;
            margin-bottom: 8px;
            color: #ffc107;
            display: none;
        }
        
        .api-warning.visible {
            display: block;
        }
        
        /* DIFF-SPECIFIC STYLES */
        .diff-block {
            background: rgba(107, 70, 193, 0.05);
            border-left: 3px solid var(--accent);
            padding: 8px;
            margin: 8px 0;
            border-radius: 4px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 0.9em;
        }
        
        .diff-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
            padding-bottom: 4px;
            border-bottom: 1px solid var(--border);
        }
        
        .diff-actions {
            display: flex;
            gap: 4px;
            margin-top: 8px;
        }
        
        .diff-action-btn {
            font-size: 0.8em;
            padding: 2px 8px;
            border-radius: 2px;
        }
        
        .diff-line {
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            white-space: pre;
        }
        
        .diff-line.add {
            background: rgba(16, 185, 129, 0.1);
            color: var(--success);
        }
        
        .diff-line.remove {
            background: rgba(220, 53, 69, 0.1);
            color: var(--error);
        }
        
        .diff-line.context {
            color: var(--secondary);
        }
        
        .validation-result {
            padding: 8px;
            border-radius: 4px;
            margin: 8px 0;
            font-size: 0.9em;
        }
        
        .validation-valid {
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.3);
        }
        
        .validation-invalid {
            background: rgba(220, 53, 69, 0.1);
            border: 1px solid rgba(220, 53, 69, 0.3);
        }
        
        .ai-suggestion-badge {
            display: inline-block;
            background: var(--accent);
            color: white;
            font-size: 0.7em;
            padding: 1px 6px;
            border-radius: 10px;
            margin-left: 8px;
            vertical-align: middle;
        }

        .chat-history {
            flex: 1;
            overflow-y: auto;
            padding: 8px;
            margin-bottom: 8px;
            background: var(--input-background);
            border-radius: 4px;
            border: 1px solid var(--border);
            position: relative;
            resize: vertical;
            min-height: 100px;
            max-height: 400px;
        }

        .scroll-to-bottom {
            background: transparent;
            border: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            opacity: 0;
            transition: opacity 0.2s;
            z-index: 100;
        }

        .scroll-to-bottom.visible {
            opacity: 1;
        }

        .scroll-to-bottom:hover {
            background: var(--accent);
            transform: scale(1.1);
        }

        /* Diff display improvements */
        .diff-header {
            display: flex;
            flex-direction: column;
            margin-bottom: 8px;
            padding-bottom: 4px;
            border-bottom: 1px solid var(--border);
        }

        .diff-header strong {
            margin-bottom: 4px;
            color: var(--accent);
        }

        .diff-explanation {
            font-size: 0.8em;
            color: var(--secondary);
            line-height: 1.4;
            margin-top: 4px;
        }

        /* Diff line coloring */
        .diff-line {
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            white-space: pre;
            margin: 1px 0;
            padding: 0 2px;
            border-radius: 2px;
        }

        .diff-line.add {
            background: rgba(16, 185, 129, 0.15);
            color: var(--success);
        }

        .diff-line.remove {
            background: rgba(220, 53, 69, 0.15);
            color: var(--error);
        }

        .diff-line.context {
            color: var(--secondary);
            opacity: 0.7;
        }

        .diff-line.header {
            color: var(--accent);
            font-weight: bold;
            background: rgba(107, 70, 193, 0.1);
        }
        .validation-result {
            padding: 12px;
            border-radius: 6px;
            margin: 12px 0;
            border-left: 4px solid;
            animation: slideIn 0.3s ease-out;
        }
        
        .validation-valid {
            background: rgba(16, 185, 129, 0.1);
            border-left-color: var(--success);
        }
        
        .validation-invalid {
            background: rgba(220, 53, 69, 0.1);
            border-left-color: var(--error);
        }
        
        .validation-result h4 {
            margin: 0 0 8px 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .validation-result ul {
            margin: 8px 0;
            padding-left: 20px;
        }
        
        .validation-result li {
            margin: 4px 0;
            line-height: 1.4;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
    </style>
</head>
<body>
    <div class="settings-panel" id="settingsPanel">
        <div class="settings-header">
            <h3>⚙️ OpenRouter Configuration</h3>
            <button class="toggle-settings" id="closeSettingsBtn">✕</button>
        </div>
        
        <div class="settings-input-group">
            <label class="settings-label" for="apiKeyInput">API Key</label>
            <input type="password" 
                   class="settings-input" 
                   id="apiKeyInput" 
                   placeholder="sk-or-v1-..."
                   spellcheck="false">
            <div class="settings-hint">
                🔑 Get your key from: <a href="https://openrouter.ai/settings/keys" target="_blank">openrouter.ai/settings/keys</a>
            </div>
        </div>
        
        <div class="settings-input-group">
            <label class="settings-label" for="modelSelect">Model</label>
            <select class="settings-input" id="modelSelect">
                <option value="">Loading models...</option>
            </select>
            <div id="modelInfo" class="model-info"></div>
        </div>
        
        <div class="settings-input-group">
            <label class="settings-label" for="httpRefererInput">HTTP Referer (Optional)</label>
            <input type="text" 
                   class="settings-input" 
                   id="httpRefererInput" 
                   placeholder="https://github.com/yourusername"
                   spellcheck="false">
            <div class="settings-hint">
                Used for OpenRouter leaderboard attribution
            </div>
        </div>
        
        <div class="settings-input-group">
            <label class="settings-label" for="xTitleInput">App Title (Optional)</label>
            <input type="text" 
                   class="settings-input" 
                   id="xTitleInput" 
                   placeholder="OpenRouter VS Code Extension"
                   spellcheck="false">
            <div class="settings-hint">
                Display name for your app on OpenRouter
            </div>
        </div>
        
        <div class="settings-input-group">
            <label class="settings-label" style="display: flex; align-items: center; gap: 8px;">
                <input type="checkbox" id="saveHistoryCheckbox" checked>
                Save chat history between sessions
            </label>
            <div class="settings-hint">
                When enabled, your conversations will be saved and restored when you reopen VS Code
            </div>
        </div>

        <button id="saveConfigBtn" class="accent-btn">💾 Save Configuration</button>
        
        <div class="current-model" id="currentConfig">
            Loading current configuration...
        </div>
    </div>
    
    <div class="api-warning" id="apiWarning">
        ⚠️ API key not configured. Please open settings to configure your OpenRouter API key.
    </div>
    
    <div class="chat-container">
        <div class="chat-history" id="chatHistory">
            <!-- Chat messages will appear here -->
        </div>
        
        <div class="error" id="errorMessage"></div>
        <div class="success" id="successMessage"></div>
        
        <div class="loading" id="loadingIndicator">
            <span>Thinking...</span>
            <span class="loading-timer" id="loadingTimer">0ms</span>
        </div>
        
        <div class="input-area">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
                <div style="display: flex; align-items: center; gap: 8px;" id="chat-settings">
                    <button id="settingsBtn" class="secondary-btn" style="font-size: 0.9em; padding: 4px 8px;">
                        ⚙️ Settings
                    </button>
                    <!-- Scroll button will be inserted here programmatically -->
                </div>
                <span id="currentModelBadge" style="font-size: 0.8em; color: var(--secondary);"></span>
            </div>
            
            <textarea 
                id="messageInput" 
                placeholder="Ask AI anything... (Enter to send)"
                spellcheck="false"
                style="resize: vertical; min-height: 60px; max-height: 200px; margin-bottom: 8px;"></textarea>
            
            <textarea 
                id="codeContextInput" 
                placeholder="📝 Paste code context here (optional)..."
                spellcheck="false"
                style="resize: vertical; min-height: 60px; max-height: 300px; font-size: 0.9em;"></textarea>
            
            <div class="button-row">
                <button id="loadCodeBtn" class="secondary-btn" title="Load code from active editor">
                    📄 Load Active File
                </button>
                
                <button id="clearHistoryBtn" class="secondary-btn" title="Clear chat history">
                    🗑️ Clear
                </button>
                
                <button id="sendBtn" class="accent-btn">
                    Send
                </button>
                
                <button class="stop-btn" id="stopBtn">
                    Stop
                </button>
            </div>
            
            <div class="action-buttons">
                <button class="action-btn secondary-btn" id="commentBtn">
                    💬 Request Comment
                </button>
                <button class="action-btn secondary-btn" id="diffBtn">
                    📝 Request Code Change
                </button>
            </div>
        </div>
        <div class="diff-block">
            <div class="diff-header">
                <strong>🤖 AI Code Suggestion</strong>
                <div class="diff-explanation">{{explanation}}</div>
                {{#if patchFile}}
                <div class="patch-info" style="font-size: 0.8em; color: var(--success); margin-top: 4px;">
                    ✅ Patch saved: {{patchFileName}}
                </div>
                {{/if}}
            </div>
            
            <div class="diff-content">
                {{diffContent}}
            </div>
            
            <div class="diff-actions">
                <button class="diff-action-btn" onclick="validateDiff('{{diff}}')">
                    Validate
                </button>
                <button class="diff-action-btn" onclick="previewDiff('{{diff}}', '{{explanation}}')">
                    Preview
                </button>
                <button class="diff-action-btn" onclick="applyDiff('{{diff}}', '{{explanation}}')">
                    Apply in Editor
                </button>
                {{#if patchFile}}
                <button class="diff-action-btn" onclick="copyGitCommand('{{gitCommand}}')" 
                        style="background: var(--accent); color: white;">
                    📋 Copy Git Command
                </button>
                <button class="diff-action-btn" onclick="applyGitPatch('{{patchFile}}')"
                        style="background: var(--success); color: white;">
                    🚀 Apply via Git
                </button>
                {{/if}}
            </div>
        </div>
    </div>
    
    <div id="diffPreviewModal" style="display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center;">
        <div style="background: var(--background); padding: 20px; border-radius: 8px; max-width: 90%; max-height: 90%; overflow: auto;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
                <h3 style="margin: 0;">Diff Preview</h3>
                <button id="closePreviewBtn" style="background: none; border: none; color: var(--secondary); cursor: pointer; font-size: 1.2em;">✕</button>
            </div>
            <div id="diffPreviewContent"></div>
            <div style="margin-top: 16px; display: flex; gap: 8px; justify-content: flex-end;" id="previewModalActions">
                <!-- Buttons will be added here programmatically -->
            </div>
        </div>
    </div>

    <script nonce="${nonce}">
        const vscode = acquireVsCodeApi();

        // REST OF ORIGINAL JAVASCRIPT CODE FOR CHAT FUNCTIONALITY
        let currentMessageId = 1;
        let isStreaming = false;
        let currentStreamMessageId = null;
        let availableModels = [];
        let hasApiKey = false;

        // Add to top of script
        let autoScrollEnabled = true;
        let isUserScrolling = false;
        let scrollTimeout = null;

        let currentDiff = null;
        let currentDiffExplanation = null;
        
        // DOM Elements
        const settingsPanel = document.getElementById('settingsPanel');
        const settingsBtn = document.getElementById('settingsBtn');
        const closeSettingsBtn = document.getElementById('closeSettingsBtn');
        const saveConfigBtn = document.getElementById('saveConfigBtn');
        const sendBtn = document.getElementById('sendBtn');
        const messageInput = document.getElementById('messageInput');
        const loadCodeBtn = document.getElementById('loadCodeBtn');
        const clearHistoryBtn = document.getElementById('clearHistoryBtn');
        const stopBtn = document.getElementById('stopBtn');
        const commentBtn = document.getElementById('commentBtn');
        const diffBtn = document.getElementById('diffBtn');
        const apiWarning = document.getElementById('apiWarning');


        // DIFF-SPECIFIC FUNCTIONS
        function showDiffInResponse(messageId, diff, explanation) {
            const messageEl = document.getElementById(messageId);
            if (!messageEl) return;
            
            const diffContainer = document.createElement('div');
            diffContainer.className = 'diff-block';
            
            // Parse and colorize the diff
            const diffLines = diff.split('\\n');
            let diffHtml = '';
            
            diffLines.forEach(line => {
                if (line.startsWith('@@')) {
                    diffHtml += '<div class="diff-line header">' + escapeHtml(line) + '</div>';
                } else if (line.startsWith('+')) {
                    diffHtml += '<div class="diff-line add">' + escapeHtml(line) + '</div>';
                } else if (line.startsWith('-')) {
                    diffHtml += '<div class="diff-line remove">' + escapeHtml(line) + '</div>';
                } else if (line.startsWith(' ')) {
                    diffHtml += '<div class="diff-line context">' + escapeHtml(line) + '</div>';
                } else {
                    diffHtml += '<div>' + escapeHtml(line) + '</div>';
                }
            });
            
            diffContainer.innerHTML = 
                '<div class="diff-header">' +
                    '<strong>🤖 AI Code Suggestion</strong>' +
                    '<div class="diff-explanation">' + escapeHtml(explanation) + '</div>' +
                '</div>' +
                '<div style="margin: 0; padding: 8px; background: rgba(0,0,0,0.03); border-radius: 4px; overflow: auto; max-height: 300px; font-size: 0.85em; font-family: monospace;">' + 
                    diffHtml + 
                '</div>' +
                '<div class="diff-actions" id="diffActions_' + messageId + '"></div>';
            
            messageEl.appendChild(diffContainer);
            
            // Create buttons programmatically (FIXED EVENT HANDLING)
            const actionsDiv = document.getElementById('diffActions_' + messageId);
            const buttonData = [
                { text: 'Validate', style: 'warning', action: () => validateDiff(diff) },
                { text: 'Preview', style: 'accent', action: () => previewDiff(diff, explanation) },
                { text: 'Apply', style: 'success', action: () => applyDiff(diff, explanation) },
                { text: 'Save', style: 'secondary', action: () => saveDiff(diff, explanation) }
            ];
            
            buttonData.forEach(btnData => {
                const button = document.createElement('button');
                button.className = 'diff-action-btn';
                button.textContent = btnData.text;
                if (btnData.style === 'warning') {
                    button.style.background = 'var(--warning)';
                    button.style.color = 'white';
                } else if (btnData.style === 'accent') {
                    button.style.background = 'var(--accent)';
                    button.style.color = 'white';
                } else if (btnData.style === 'success') {
                    button.style.background = 'var(--success)';
                    button.style.color = 'white';
                }
                button.addEventListener('click', btnData.action);
                actionsDiv.appendChild(button);
            });
        }

        // Helper functions
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        function validateDiff(diff) {
            vscode.postMessage({
                command: 'validateDiff',
                diff: diff
            });
        }
        
        function copyGitCommand(command) {
            vscode.postMessage({
                command: 'copyToClipboard',
                text: command
            });
        }

        function applyGitPatch(patchPath) {
            if (confirm('Apply this patch using git apply?')) {
                vscode.postMessage({
                    command: 'applyGitPatch',
                    patchPath: patchPath
                });
            }
        }

        // FIXED: Using \\n for embedded JavaScript strings
        function showValidationResult(isValid, errors, warnings) {
            
            // Create a more prominent notification
            const notification = document.createElement('div');
            notification.id = 'diffValidId';
            notification.className = 'validation-result ' + (isValid ? 'validation-valid' : 'validation-invalid');
            
            // FIX opacity: Add transparency for background
            notification.style.cssText = 
                'position: fixed;' +
                'top: 20px;' +
                'right: 20px;' +
                'z-index: 1000;' +
                'width: 400px;' +
                'max-width: 90%;' +
                'animation: slideInRight 0.3s ease-out;' +
                'background: var(--vscode-editor-background);' +
                'opacity: 0.95;' +
                'border: 1px solid var(--vscode-panel-border);' +
                'box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);' +
                'backdrop-filter: blur(5px);' +
                'border-radius: 6px;' +
                'overflow: hidden;';
            
            // Add close button
            let html = '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; padding: 12px 16px; border-bottom: 1px solid var(--vscode-panel-border); background: rgba(0,0,0,0.05);">';
            html += '<h4 style="margin: 0; font-size: 14px; font-weight: 600;">' + 
                    (isValid ? '✅ Diff is Valid!' : '❌ Diff Validation Failed') + '</h4>';
            html += '<button onclick="window.closeValidationNotification_' + diffValidId + '()" style="background: none; border: none; color: var(--vscode-foreground); cursor: pointer; font-size: 1.2em; padding: 2px 8px; border-radius: 3px; transition: background 0.2s;">';
            html += '✕</button>';
            html += '</div>';
            
            // Content area with padding
            html += '<div style="padding: 16px; max-height: 300px; overflow-y: auto;">';
            
            if (isValid && warnings.length === 0) {
                html += '<p style="margin: 0; color: var(--vscode-foreground);">✅ Diff syntax is correct and ready to apply.</p>';
            }
            
            if (warnings.length > 0) {
                html += '<p style="margin: 0 0 8px 0; color: var(--vscode-list-warningForeground); font-weight: 500;"><strong>⚠️ Warnings:</strong></p>';
                html += '<ul style="margin: 0 0 12px 0; padding-left: 20px;">';
                warnings.forEach(function(warning) {
                    html += '<li style="margin: 4px 0; color: var(--vscode-list-warningForeground);">' + escapeHtml(warning) + '</li>';
                });
                html += '</ul>';
            }
            
            if (errors.length > 0) {
                html += '<p style="margin: 0 0 8px 0; color: var(--vscode-errorForeground); font-weight: 500;"><strong>❌ Errors:</strong></p>';
                html += '<ul style="margin: 0; padding-left: 20px;">';
                errors.forEach(function(error) {
                    html += '<li style="margin: 4px 0; color: var(--vscode-errorForeground);">' + escapeHtml(error) + '</li>';
                });
                html += '</ul>';
            }
            
            html += '</div>';
            
            notification.innerHTML = html;
            
            // Make the close function globally accessible with unique name
            window['closeValidationNotification_' + diffValidId] = closeDiffValidContainer;
            
            // Add to body instead of chat history
            document.body.appendChild(notification);
            
            // Auto-remove after 15 seconds
            setTimeout(function() {
                closeDiffValidContainer();
                // Clean up the global function
                delete window['closeValidationNotification_' + diffValidId];
            }, 15000);
            
            // Add CSS animation if not already present
            if (!document.querySelector('#validation-styles')) {
                const style = document.createElement('style');
                style.id = 'validation-styles';
                style.textContent = 
                    '@keyframes slideInRight {' +
                    '    from {' +
                    '        transform: translateX(100%);' +
                    '        opacity: 0;' +
                    '    }' +
                    '    to {' +
                    '        transform: translateX(0);' +
                    '        opacity: 0.95;' +
                    '    }' +
                    '}' +
                    '' +
                    '@keyframes fadeOut {' +
                    '    from { opacity: 0.95; }' +
                    '    to { opacity: 0; }' +
                    '}' +
                    '' +
                    '.validation-result {' +
                    '    transition: opacity 0.3s ease-out;' +
                    '}' +
                    '' +
                    '.validation-result.fading {' +
                    '    animation: fadeOut 0.3s ease-out forwards;' +
                    '}';
                document.head.appendChild(style);
            }
        }

        // Create close button function
        function closeDiffValidContainer() {
            const element = document.getElementById(diffValidId);
            if (element && element.parentNode) {
                element.parentNode.removeChild(element);
            }
        };
        

        // ALSO FIXED: Use \\n for split in embedded JavaScript
        function showDiffExtracted(diff, explanation) {
            const previewDiv = document.getElementById('diffPreviewContent');
            if (previewDiv) {
                const lines = diff.split('\\n');  // FIXED: Use \\n for embedded JS
                let html = '<div style="font-family: monospace; font-size: 0.9em;">';
                html += '<p style="color: var(--secondary); margin-bottom: 10px;">' + escapeHtml(explanation) + '</p>';
                
                lines.forEach(line => {
                    if (line.startsWith('+')) {
                        html += '<div class="diff-line add">' + escapeHtml(line) + '</div>';
                    } else if (line.startsWith('-')) {
                        html += '<div class="diff-line remove">' + escapeHtml(line) + '</div>';
                    } else if (line.startsWith('@@')) {
                        html += '<div style="color: var(--accent); font-weight: bold;">' + escapeHtml(line) + '</div>';
                    } else if (line.startsWith('---') || line.startsWith('+++')) {
                        html += '<div style="color: #666;">' + escapeHtml(line) + '</div>';
                    } else {
                        html += '<div class="diff-line context">' + escapeHtml(line) + '</div>';
                    }
                });
                html += '</div>';
                
                previewDiv.innerHTML = html;
                setupPreviewModalButtons(diff, explanation);
                document.getElementById('diffPreviewModal').style.display = 'flex';
            }
        }

        function applyDiff(diff, explanation) {
            if (confirm('Apply this diff to the current file?')) {
                vscode.postMessage({
                    command: 'applyDiff',
                    diff: diff,
                    explanation: explanation
                });
            }
        }
        
        function saveDiff(diff, explanation) {
            // Show saving indicator
            const saveIndicator = document.createElement('div');
            saveIndicator.className = 'validation-result validation-valid';
            saveIndicator.style.cssText = 'position: fixed; top: 20px; right: 20px; z-index: 1000; width: 300px;';
            saveIndicator.innerHTML = '<h4>💾 Saving...</h4><p>Saving AI suggestion to help file...</p>';
            document.body.appendChild(saveIndicator);
            
            // Send save command
            vscode.postMessage({
                command: 'saveDiff',
                diff: diff,
                explanation: explanation
            });
            
            // Remove indicator after response or timeout
            setTimeout(() => {
                if (saveIndicator.parentNode) {
                    saveIndicator.remove();
                }
            }, 3000);
        }
        
        function previewDiff(diff, explanation) {
            currentDiff = diff;
            currentDiffExplanation = explanation;
            
            // FIX: Use single backslash for split
            const lines = diff.split('\\n');
            let html = '<div style="font-family: monospace; font-size: 0.9em;">';
            lines.forEach(line => {
                if (line.startsWith('+')) {
                    html += '<div class="diff-line add">' + escapeHtml(line) + '</div>';
                } else if (line.startsWith('-')) {
                    html += '<div class="diff-line remove">' + escapeHtml(line) + '</div>';
                } else if (line.startsWith('@@')) {
                    html += '<div style="color: var(--accent); font-weight: bold;">' + escapeHtml(line) + '</div>';
                } else {
                    html += '<div class="diff-line context">' + escapeHtml(line) + '</div>';
                }
            });
            html += '</div>';
            
            document.getElementById('diffPreviewContent').innerHTML = html;
            setupPreviewModalButtons(diff, explanation);
            document.getElementById('diffPreviewModal').style.display = 'flex';
        }
        
        function setupPreviewModalButtons(diff, explanation) {
            const actionsDiv = document.getElementById('previewModalActions');
            if (!actionsDiv) return;
            
            // Clear any existing buttons
            actionsDiv.innerHTML = '';
            
            // Setup close button
            const closeBtn = document.getElementById('closePreviewBtn');
            if (closeBtn) {
                closeBtn.onclick = closeDiffPreview;
            }
            
            // Create action buttons programmatically
            const buttonData = [
                { 
                    text: 'Apply', 
                    style: 'success',
                    action: () => {
                        if (currentDiff && currentDiffExplanation) {
                            vscode.postMessage({
                                command: 'applyDiff',
                                diff: currentDiff,
                                explanation: currentDiffExplanation
                            });
                        }
                        closeDiffPreview();
                    }
                },
                { 
                    text: 'Save', 
                    style: 'accent',
                    action: () => {
                        if (currentDiff && currentDiffExplanation) {
                            vscode.postMessage({
                                command: 'saveDiff',
                                diff: currentDiff,
                                explanation: currentDiffExplanation
                            });
                        }
                        closeDiffPreview();
                    }
                },
                { 
                    text: 'Cancel', 
                    style: 'secondary',
                    action: closeDiffPreview
                }
            ];
            
            buttonData.forEach(btnData => {
                const button = document.createElement('button');
                button.textContent = btnData.text;
                button.style.padding = '8px 16px';
                button.style.border = 'none';
                button.style.borderRadius = '4px';
                button.style.cursor = 'pointer';
                button.style.fontFamily = 'var(--vscode-font-family)';
                
                if (btnData.style === 'success') {
                    button.style.background = 'var(--success)';
                    button.style.color = 'white';
                } else if (btnData.style === 'accent') {
                    button.style.background = 'var(--accent)';
                    button.style.color = 'white';
                } else {
                    button.style.background = 'var(--secondary)';
                    button.style.color = 'white';
                }
                
                button.addEventListener('click', btnData.action);
                actionsDiv.appendChild(button);
            });
        }

        function closeDiffPreview() {
            document.getElementById('diffPreviewModal').style.display = 'none';
            currentDiff = null;
            currentDiffExplanation = null;
        }
        
        
        // Message handler for diff-related messages
        window.addEventListener('message', (event) => {
            const message = event.data;
            
            switch (message.command) {
                case 'diffValidation':
                    showValidationResult(message.isValid, message.errors, message.warnings);
                    break;
                    
                case 'diffExtracted':
                    if (message.found) {
                        showDiffExtracted(message.diff, message.explanation);
                    }
                    break;
                    
                case 'chatComplete':
                    if (message.containsDiff && message.diff) {
                        // Find the last assistant message and add diff controls
                        const messages = document.querySelectorAll('.assistant-message');
                        if (messages.length > 0) {
                            const lastMessage = messages[messages.length - 1];
                            setTimeout(() => {
                                showDiffInResponse(lastMessage.id, message.diff, message.explanation || 'AI suggestion');
                            }, 100);
                        }
                    }
                    break;

                // ADD THE NEW CASE HERE:
                case 'diffSaved':
                    showMessage(
                        message.success ? '✅ Diff saved to help file!' : '❌ Failed to save diff: ' + (message.message || ''),
                        message.success ? 'success' : 'error'
                    );
                    break;
                
                case 'patchSaved':
                    showPatchSavedNotification(message.patchPath, message.gitCommand);
                    break;
                    
                case 'gitPatchApplied':
                    if (message.success) {
                        showMessage('✅ Patch applied via git!', 'success');
                    } else {
                                showMessage('❌ Git apply failed: ' + message.error, 'error');
                    }
                    break;
                    
                case 'clipboardCopied':
                    showMessage('📋 Git command copied to clipboard!', 'success');
                    break;
            }
        });
        
        
        function setupEventListeners() {
            // Settings button
            settingsBtn.addEventListener('click', () => {
                console.log('Settings button clicked');
                toggleSettings();
            });
            
            // Close settings button
            closeSettingsBtn.addEventListener('click', () => {
                console.log('Close settings button clicked');
                hideSettings();
            });
            
            // Save configuration button
            saveConfigBtn.addEventListener('click', () => {
                console.log('Save configuration button clicked');
                saveConfiguration();
            });
            
            // Send button
            sendBtn.addEventListener('click', () => {
                console.log('Send button clicked');
                sendMessage();
            });
            
            // Load code button
            loadCodeBtn.addEventListener('click', () => {
                console.log('Load code button clicked');
                getActiveCode();
            });
            
            // Clear history button
            clearHistoryBtn.addEventListener('click', () => {
                console.log('Clear history button clicked');
                clearHistory();
            });
            
            // Stop button
            stopBtn.addEventListener('click', () => {
                console.log('Stop button clicked');
                stopRequest();
            });
            
            // Action buttons
            commentBtn.addEventListener('click', insertCommentRequest);
            diffBtn.addEventListener('click', insertDiffRequest);
            
            // Keyboard shortcut: Enter to send
            messageInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    console.log('Enter pressed');
                    sendMessage();
                }
            });

            // Add event listener for save history checkbox
            const saveHistoryCheckbox = document.getElementById('saveHistoryCheckbox');
            if (saveHistoryCheckbox) {
                saveHistoryCheckbox.addEventListener('change', () => {
                    vscode.postMessage({
                        command: 'updateSaveSetting',
                        enabled: saveHistoryCheckbox.checked
                    });
                });
            }
        }
        
        function showPatchSavedNotification(patchPath: string, gitCommand: string): void {
            const notification = document.createElement('div');
            notification.className = 'validation-result validation-valid';
            notification.style.cssText = 'position: fixed; top: 20px; right: 20px; z-index: 1000; width: 400px;';
            
            const relativePath = patchPath.split('.patches/').pop() || patchPath;
            
            // FIXED: Use string concatenation instead of template literal
            notification.innerHTML = 
                '<h4>✅ Patch Saved</h4>' +
                '<p>Saved to: <code>' + escapeHtml(relativePath) + '</code></p>' +
                '<p>Apply from console:</p>' +
                '<pre style="background: rgba(0,0,0,0.1); padding: 8px; border-radius: 4px; font-size: 0.9em;">' +
                '    cd /path/to/project' +
                '    ' + escapeHtml(gitCommand) + '</pre>' +
                '<div style="display: flex; gap: 8px; margin-top: 12px;">' +
                '    <button onclick="copyToClipboard(\'' + escapeHtml(gitCommand) + '\')" style="padding: 4px 8px; font-size: 0.9em;">' +
                '        Copy Command' +
                '    </button>' +
                '    <button onclick="closeNotification(this)" style="padding: 4px 8px; font-size: 0.9em;">' +
                '        Dismiss' +
                '    </button>' +
                '</div>';
            
            document.body.appendChild(notification);
            
            // Auto-remove after 10 seconds
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.remove();
                }
            }, 10000);
        }

        // Message handler from extension
        window.addEventListener('message', (event) => {
            const message = event.data;
            console.log('Received message from extension:', message.command);
            
            switch (message.command) {
                case 'apiKeyRequired':
                    console.log('API key required');
                    showSettings();
                    showMessage('Please configure your OpenRouter API key', 'error');
                    apiWarning.classList.add('visible');
                    break;
                
                case 'configurationSaved':
                    console.log('Configuration saved');
                    hideSettings();
                    showMessage('Configuration saved successfully!', 'success');
                    hasApiKey = true;
                    apiWarning.classList.remove('visible');
                    // Update the badge with the new model
                    updateModelBadge(message.model);
                    
                    // Also update the full config display
                    updateCurrentConfigDisplay(message);
                    break;
                
                case 'availableModels':
                    console.log('Available models received:', message.models.length);
                    availableModels = message.models;
                    populateModelSelect();
                    break;
                
                case 'chatHistoryLoaded':
                    console.log('Chat history loaded:', message.history.length, 'messages');
                    // Clear current display
                    document.getElementById('chatHistory').innerHTML = '';
                    
                    // Add each message
                    message.history.forEach(msg => {
                        addMessage(
                            msg.role, 
                            msg.content, 
                            new Date(msg.timestamp), 
                            msg.model || '',
                            msg.containsDiff,
                            msg.diff,
                            msg.explanation
                        );
                    });
                    break;
                
                case 'currentConfig':
                    console.log('Current config received');
                    hasApiKey = message.hasApiKey;
                    updateCurrentConfigDisplay(message);
                    
                    // Update save history checkbox
                    if (saveHistoryCheckbox) {
                        saveHistoryCheckbox.checked = message.saveChatHistory !== false;
                    }
                    
                    if (!hasApiKey) {
                        apiWarning.classList.add('visible');
                    }
                    break;
                
                case 'saveSettingUpdated':
                    showMessage(
                        message.enabled 
                            ? 'Chat history saving enabled' 
                            : 'Chat history saving disabled',
                        'success'
                    );
                    break;

                case 'activeCode':
                    console.log('Active code received');
                    
                    // Set code ONLY in code context area - FIXED
                    const codeContextInput = document.getElementById('codeContextInput');
                    if (codeContextInput) {
                        codeContextInput.value = message.code || '';
                        if (message.code) {
                            codeContextInput.focus();  // Optional: focus the code area
                        }
                    }
                    break;
                
                // Then in the loading case handler, add more logging:
                case 'loading':
                    console.log('Loading state received:', message.loading);
                    console.log('isStreaming before:', isStreaming);
                    console.log('currentStreamMessageId before:', currentStreamMessageId);
                    
                    const loading = document.getElementById('loadingIndicator');
                    const stopBtn = document.getElementById('stopBtn');
                    const sendBtn = document.getElementById('sendBtn');
                    
                    if (message.loading) {
                        console.log('Creating placeholder message...');
                        loading.classList.add('active');
                        stopBtn.style.display = 'block';
                        sendBtn.disabled = true;
                        isStreaming = true;
                        
                        // Start the timer
                        startLoadingTimer();

                        // Create placeholder message
                        const history = document.getElementById('chatHistory');
                        console.log('History element found:', !!history);
                        
                        if (history) {
                            const messageId = 'msg-' + currentMessageId++;
                            console.log('Creating message with ID:', messageId);
                            currentStreamMessageId = messageId;
                            
                            const messageEl = document.createElement('div');
                            messageEl.id = messageId;
                            messageEl.className = 'message assistant-message';
                            
                            const timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                            
                            messageEl.innerHTML = 
                                '<div class="message-header">' +
                                    '<span class="message-model">AI Assistant</span>' +
                                    '<span>' + timeStr + '</span>' +
                                '</div>' +
                                '<div class="message-content">Thinking...</div>';
                            
                            history.appendChild(messageEl);
                            console.log('Placeholder message added to DOM');
                            
                            // Try to scroll it into view
                            setTimeout(() => {
                                messageEl.scrollIntoView({ behavior: 'smooth', block: 'end' });
                            }, 100);
                        }
                    } else {
                        console.log('Ending streaming...');
                        loading.classList.remove('active');
                        stopBtn.style.display = 'none';
                        sendBtn.disabled = false;
                        isStreaming = false;
                        currentStreamMessageId = null;
                        console.log('isStreaming after:', isStreaming);

                        // Stop the timer
                        stopLoadingTimer();
                    }
                    break;
                
                case 'streamChunk':
                    console.log('Stream chunk received, length:', message.content?.length);
                    console.log('isStreaming:', isStreaming);
                    console.log('currentStreamMessageId:', currentStreamMessageId);
                    
                    if (isStreaming && currentStreamMessageId) {
                        const messageEl = document.getElementById(currentStreamMessageId);
                        console.log('Message element found:', !!messageEl);
                        
                        if (messageEl) {
                            const contentEl = messageEl.querySelector('.message-content');
                            console.log('Content element found:', !!contentEl);
                            
                            if (contentEl) {
                                // Replace "Thinking..." with actual content
                                if (contentEl.textContent === 'Thinking...') {
                                    contentEl.textContent = message.content;
                                } else {
                                    contentEl.textContent += message.content;
                                }
                                console.log('Content updated, new length:', contentEl.textContent.length);
                            }
                        }
                    } else {
                        console.log('WARNING: Received streamChunk but not streaming or no message ID');
                    }
                    break;

                case 'chatComplete':
                    console.log('Chat complete, containsDiff:', message.containsDiff);
                    isStreaming = false;
                    
                    currentStreamMessageId = null;
                    break;
                
                case 'historyCleared':
                    console.log('History cleared');
                    document.getElementById('chatHistory').innerHTML = '';
                    break;
                
                case 'error':
                    console.log('Error received:', message.message);
                    showMessage(message.message, 'error');
                    break;
                
                case 'showSettings':
                    console.log('Show settings command received');
                    showSettings();
                    break;
                
                case 'testResponse':
                    console.log('Test successful:', message.message);
                    break;
            }
        });
        
        function addMessage(role, content, timestamp, model = '', containsDiff = false, diff = '', explanation = '', id = null) {
            const history = document.getElementById('chatHistory');
            const messageId = id || 'msg-' + currentMessageId++;
            const timeStr = timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            
            const messageEl = document.createElement('div');
            messageEl.id = messageId;
            messageEl.className = 'message ' + role + '-message';
            
            let header = '<div class="message-header">' +
                '<span>' + (role === 'user' ? 'You' : 'AI Assistant') + '</span>' +
                '<span>' + timeStr + '</span>' +
                '</div>';
            
            if (role === 'assistant' && model) {
                const modelName = availableModels.find(m => m.id === model)?.name || model.split('/').pop();
                header = '<div class="message-header">' +
                    '<span class="message-model">' + modelName + '</span>' +
                    '<span>' + timeStr + '</span>' +
                    '</div>';
            }
            
            messageEl.innerHTML = header +
                '<div class="message-content">' + escapeHtml(content) + '</div>';
            
            history.appendChild(messageEl);
            messageEl.scrollIntoView({ behavior: 'smooth', block: 'end' });
            
            return messageId;
        }
        
        function toggleSettings() {
            console.log('toggleSettings called');
            if (settingsPanel.classList.contains('visible')) {
                hideSettings();
            } else {
                showSettings();
            }
        }
        
        function showSettings() {
            console.log('Showing settings panel');
            settingsPanel.classList.add('visible');
            getCurrentConfig();
        }
        
        function hideSettings() {
            console.log('Hiding settings panel');
            settingsPanel.classList.remove('visible');
        }
        
        function loadModels() {
            console.log('Loading models...');
            vscode.postMessage({
                command: 'getAvailableModels'
            });
        }
        
        function populateModelSelect() {
            const select = document.getElementById('modelSelect');
            select.innerHTML = '';
            
            availableModels.forEach(model => {
                const option = document.createElement('option');
                option.value = model.id;
                option.textContent = model.provider + ' - ' + model.name;
                select.appendChild(option);
            });
            
            select.addEventListener('change', updateModelInfo);
            console.log('Model select populated with', availableModels.length, 'models');
        }
        
        function updateModelInfo() {
            const select = document.getElementById('modelSelect');
            const selectedModelId = select.value;
            const selectedModel = availableModels.find(m => m.id === selectedModelId);
            
            if (selectedModel) {
                const modelInfo = document.getElementById('modelInfo');
                const providerSpan = document.createElement('span');
                providerSpan.className = 'model-provider';
                providerSpan.textContent = selectedModel.provider;
                
                modelInfo.innerHTML = '';
                modelInfo.appendChild(providerSpan);
                modelInfo.appendChild(document.createTextNode(' • ' + selectedModel.description));
            }
        }
        
        function getCurrentConfig() {
            console.log('Getting current config...');
            vscode.postMessage({
                command: 'getCurrentConfig'
            });
        }
        
        function updateCurrentConfigDisplay(config) {
            console.log('Updating config display:', config);
            
            if (!config) return;
            
            const apiKeyInput = document.getElementById('apiKeyInput');
            const httpRefererInput = document.getElementById('httpRefererInput');
            const xTitleInput = document.getElementById('xTitleInput');
            const modelSelect = document.getElementById('modelSelect');
            
            // FIX: Don't clear the API key input if API key exists
            if (apiKeyInput) {
                if (config.hasApiKey) {
                    // API key is saved but we don't show it for security
                    // Show a placeholder that indicates it's already saved
                    apiKeyInput.value = ''; // Clear the field
                    apiKeyInput.type = 'password'; // Keep it as password
                    apiKeyInput.placeholder = '••••••••••••••• (API key already saved)';
                    // Store the fact that we have an API key
                    apiKeyInput.dataset.hasApiKey = 'true';
                } else {
                    apiKeyInput.value = '';
                    apiKeyInput.type = 'password';
                    apiKeyInput.placeholder = 'sk-or-v1-...';
                    apiKeyInput.dataset.hasApiKey = 'false';
                }
            }
            
            if (httpRefererInput) httpRefererInput.value = config.httpReferer || '';
            if (xTitleInput) xTitleInput.value = config.xTitle || '';
            
            if (config.model && modelSelect) {
                modelSelect.value = config.model;
                updateModelInfo();
            }
            
            const currentConfigEl = document.getElementById('currentConfig');
            if (currentConfigEl) {
                const selectedModel = availableModels.find(m => m.id === config.model);
                currentConfigEl.innerHTML = '<div><strong>Current Model:</strong><br><span>' + 
                    (selectedModel ? selectedModel.name : config.model) + '</span></div>';
            }
            
            // Update the badge properly
            updateModelBadge(config.model);
                    
            // Update hasApiKey flag
            hasApiKey = config.hasApiKey;
        }
                        
        function saveConfiguration() {
            const apiKeyInput = document.getElementById('apiKeyInput');
            const model = document.getElementById('modelSelect').value;
            const httpReferer = document.getElementById('httpRefererInput').value.trim();
            const xTitle = document.getElementById('xTitleInput').value.trim();
            
            // Get the actual API key value
            let apiKey = apiKeyInput.value.trim();
            
            console.log('🔑 API Key input value:', apiKey ? '****' + apiKey.substring(apiKey.length - 4) : '(empty)');
            console.log('🔑 API Key input placeholder:', apiKeyInput.placeholder);
            
            // CRITICAL FIX: If user didn't change the API key field (it's empty or placeholder),
            // we should NOT send an empty string to overwrite the existing key!
            if (!apiKey || apiKey === '***************' || apiKey === '****************') {
                console.log('🔑 API key field not changed, sending null to keep existing key');
                // Send null to indicate "keep existing API key"
                apiKey = null;
            }
            
            if (!model) {
                showMessage('Please select a model', 'error');
                return;
            }
            
            console.log('💾 Saving configuration with:', {
                apiKey: apiKey === null ? '(keep existing)' : (apiKey ? '****' + apiKey.substring(apiKey.length - 4) : '(empty)'),
                model: model,
                httpReferer: httpReferer,
                xTitle: xTitle
            });
            
            vscode.postMessage({
                command: 'saveConfiguration',
                apiKey: apiKey,  // Can be null, which means "keep existing"
                model: model,
                httpReferer: httpReferer || 'https://github.com',
                xTitle: xTitle || 'OpenRouter VS Code Extension'
            });
        }

        // NEW: Separate function to update the model badge
        function updateModelBadge(modelId) {
            const badge = document.getElementById('currentModelBadge');
            if (!badge) return;
            
            if (!modelId) {
                badge.textContent = 'No model selected';
                badge.style.color = 'var(--error)';
                return;
            }
            
            const selectedModel = availableModels.find(m => m.id === modelId);
            if (selectedModel) {
                // Truncate long model names for display
                let displayName = selectedModel.provider + ' - ' + selectedModel.name;
                if (displayName.length > 40) {
                    displayName = displayName.substring(0, 37) + '...';
                }
                badge.textContent = displayName;
                badge.style.color = 'var(--accent)';
            } else {
                // Fallback to just showing the model ID
                badge.textContent = modelId.split('/').pop() || modelId;
                badge.style.color = 'var(--secondary)';
            }
        }
        
        function sendMessage() {
            const message = document.getElementById('messageInput').value.trim();
            const codeContext = document.getElementById('codeContextInput').value.trim();
            
            if (!message && !codeContext) {
                showMessage('Please enter a message or code', 'error');
                return;
            }
            
            if (!hasApiKey) {
                showSettings();
                showMessage('Please configure your API key first', 'error');
                return;
            }
            
            // Combine message and code context with line numbers - FIXED: Use string concatenation
            let combinedContent = message;
            if (codeContext) {
                if (combinedContent) combinedContent += '\\n\\n';
                combinedContent += 'Code context:\\n';
                const lines = codeContext.split('\\n');
                lines.forEach((line, index) => {
                    combinedContent += (index + 1) + ': ' + line + '\\n';  // FIXED: No template literal
                });
            }
            
            // Add to chat as user message
            const messageId = addMessage('user', combinedContent, new Date());
            
            // Clear inputs
            document.getElementById('messageInput').value = '';
            document.getElementById('codeContextInput').value = '';

            // Send to AI
            vscode.postMessage({
                command: 'chat',
                content: combinedContent
            });
        }
                
        function getActiveCode() {
            console.log('Getting active code...');
            vscode.postMessage({
                command: 'getActiveCode'
            });
        }
        
        function stopRequest() {
            console.log('Stopping request...');
            vscode.postMessage({
                command: 'stopRequest'
            });
            isStreaming = false;

            // Stop the timer
            stopLoadingTimer();
        }
        
        function clearHistory() {
            console.log('Clearing history...');
            vscode.postMessage({
                command: 'clearHistory'
            });
        }
        
        function insertCommentRequest() {
            const input = document.getElementById('messageInput');
            input.value = (input.value + '\\n\\nPlease add a comment explaining this code:').trim();
            input.focus();
        }
        
        function insertDiffRequest() {
            const input = document.getElementById('messageInput');
            input.value = (input.value + '\\n\\nPlease provide a unified diff to improve this code. Respond ONLY with the unified diff format, no explanations:').trim();
            input.focus();
        }
        
        function showMessage(text, type) {
            const errorEl = document.getElementById('errorMessage');
            const successEl = document.getElementById('successMessage');
            
            if (type === 'error') {
                errorEl.textContent = text;
                errorEl.classList.add('visible');
                successEl.classList.remove('visible');
                
                setTimeout(() => {
                    errorEl.classList.remove('visible');
                }, 5000);
            } else if (type === 'success') {
                successEl.textContent = text;
                successEl.classList.add('visible');
                errorEl.classList.remove('visible');
                
                setTimeout(() => {
                    successEl.classList.remove('visible');
                }, 3000);
            }
        }


        function setupSmartScroll() {
            const chatHistory = document.getElementById('chatHistory');
            
            // Find the container by ID
            const chatSettingsContainer = document.getElementById('chat-settings');
            
            const scrollBottomBtn = document.createElement('button');
            scrollBottomBtn.id = 'scrollBottomBtn';
            scrollBottomBtn.className = 'scroll-to-bottom'; // Same class as Settings button
            scrollBottomBtn.innerHTML = '⬇️';
            scrollBottomBtn.title = 'Scroll to bottom';
            scrollBottomBtn.style.cssText = 'font-size: 0.9em; padding: 4px 8px; margin-left: 4px; margin-right: 4px;';
            
            // Insert scroll button
            chatSettingsContainer.append(scrollBottomBtn);
            
            // Check if scroll position is at bottom
            function isAtBottom() {
                const tolerance = 5;
                return chatHistory.scrollHeight - chatHistory.scrollTop - chatHistory.clientHeight <= tolerance;
            }
            
            // Update scroll button visibility
            function updateScrollButton() {
                if (isAtBottom()) {
                    scrollBottomBtn.style.opacity = '0';
                    scrollBottomBtn.style.pointerEvents = 'none';
                    autoScrollEnabled = true;
                } else {
                    scrollBottomBtn.style.opacity = '1';
                    scrollBottomBtn.style.pointerEvents = 'auto';
                    autoScrollEnabled = false;
                }
            }
            
            // User scroll event
            chatHistory.addEventListener('scroll', () => {
                updateScrollButton();
                
                // If user scrolls up, disable auto-scroll
                if (!isAtBottom()) {
                    isUserScrolling = true;
                    clearTimeout(scrollTimeout);
                    scrollTimeout = setTimeout(() => {
                        isUserScrolling = false;
                    }, 2000); // Re-enable auto-scroll after 2 seconds of inactivity
                }
            });
            
            // Scroll to bottom button
            scrollBottomBtn.addEventListener('click', () => {
                chatHistory.scrollTop = chatHistory.scrollHeight;
                updateScrollButton();
            });
            
            // Modify existing message adding to respect scroll
            const originalAddMessage = addMessage;
            addMessage = function(...args) {
                const wasAtBottom = isAtBottom();
                const result = originalAddMessage.apply(this, args);
                
                // Only auto-scroll if at bottom and not manually scrolling
                if (wasAtBottom && autoScrollEnabled && !isUserScrolling) {
                    const messageEl = document.getElementById(args[3] || 'msg-' + (currentMessageId - 1));
                    if (messageEl) {
                        messageEl.scrollIntoView({ behavior: 'smooth', block: 'end' });
                    }
                }
                
                updateScrollButton();
                return result;
            };
            
            // Initial update
            setTimeout(updateScrollButton, 100);
        }

         // Initialize everything after DOM is loaded
        document.addEventListener('DOMContentLoaded', () => {
            console.log('DOM loaded, initializing...');
            
            // Set up scrolling
            setupSmartScroll();

            // Set up event listeners
            setupEventListeners();
            
            // Load initial data
            loadModels();
            getCurrentConfig();
            
            // REQUEST CHAT HISTORY
            vscode.postMessage({ command: 'getChatHistory' });

            // Focus the input
            messageInput.focus();
            
            // Test connection
            vscode.postMessage({ command: 'test' });
        });

        // Add these variables at the top with other global variables
        let loadingStartTime = null;
        let timerInterval = null;

        // Add this timer function
        function startLoadingTimer() {
            loadingStartTime = Date.now();
            clearInterval(timerInterval);
            
            timerInterval = setInterval(() => {
                if (loadingStartTime) {
                    const elapsed = Date.now() - loadingStartTime;
                    const timerEl = document.getElementById('loadingTimer');
                    if (timerEl) {
                        timerEl.textContent = elapsed + 'ms';
                    }
                }
            }, 50); // Update every 50ms for smooth display
        }

        function stopLoadingTimer() {
            clearInterval(timerInterval);
            timerInterval = null;
            loadingStartTime = null;
            
            const timerEl = document.getElementById('loadingTimer');
            if (timerEl) {
                timerEl.textContent = '0ms';
            }
        }

    </script>
</body>
</html>`;
    }
    getNonce() {
        let text = '';
        const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        for (let i = 0; i < 32; i++) {
            text += possible.charAt(Math.floor(Math.random() * possible.length));
        }
        return text;
    }
    dispose() {
        this._disposables.forEach(d => d.dispose());
        this.abortController?.abort();
    }
}
exports.openrouterPanel = openrouterPanel;
openrouterPanel.instance = null;
//# sourceMappingURL=webview.js.map