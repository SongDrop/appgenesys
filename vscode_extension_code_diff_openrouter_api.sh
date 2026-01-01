#!/bin/bash

# ============================================================================
# UNIFIED AI CODING ASSISTANT - VS Code Extension
# Combines: OpenRouter AI Chat + Robust Diff Application System
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "╔══════════════════════════════════════════════════╗"
echo "║           OpenRouter AI VS Code Extension        ║"
echo "║          Streamlined Chat Version                ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"



# Ask for extension name
read -p "Enter your OpenRouter extension folder name (default: openrouter-chat): " EXTNAME
EXTNAME=${EXTNAME:-openrouter-chat}

# Remove folder automatically
if [ -d "$EXTNAME" ]; then
    echo "Folder '$EXTNAME' already exists. Automatically removing it..."
    # The rm -rf command removes the folder and its contents recursively and forces the action
    rm -rf "$EXTNAME"
    echo "Folder removed. Proceeding with script."
fi

# Check if folder exists
# if [ -d "$EXTNAME" ]; then
#     read -p "Folder '$EXTNAME' already exists. Remove it? (y/N): " REMOVE
#     REMOVE=${REMOVE:-N}
#     if [[ "$REMOVE" == "y" || "$REMOVE" == "Y" ]]; then
#         echo "Removing existing folder '$EXTNAME'..."
#         rm -rf "$EXTNAME"
#     else
#         echo "Exiting to avoid overwriting."
#         exit 1
#     fi
# fi

echo "Creating extension in folder: $EXTNAME"
mkdir -p "$EXTNAME/src" "$EXTNAME/media" "$EXTNAME/scripts" "$EXTNAME/examples"
cd "$EXTNAME" || exit

# Download logo (using a generic AI logo)
echo -e "${CYAN}📥 Downloading logo...${NC}"
curl -s -o media/logo.png "https://cdn.sdappnet.cloud/rtx/images/openrouter-seeklogo.png" || echo "Using placeholder logo"

# ============================================================================
# 1. PACKAGE.JSON - Combined Extension Manifest
# ============================================================================

cat << 'EOL' > package.json
{
  "name": "openrouter-chat",
  "displayName": "OpenRouter Chat",
  "description": "AI-powered chat assistant using OpenRouter API with access to multiple models (DeepSeek, Claude, GPT, etc.)",
  "publisher": "songdropltd",
  "version": "2.0.0",
  "icon": "media/logo.png",
  "engines": {
    "vscode": "^1.81.0"
  },
  "main": "./out/extension.js",
  "scripts": {
    "compile": "tsc -p ./",
    "watch": "tsc -watch -p ./",
    "package": "vsce package"
  },
  "devDependencies": {
    "@types/node": "^20.6.2",
    "@types/vscode": "^1.81.0",
    "typescript": "^5.9.2"
  },
  "contributes": {
    "viewsContainers": {
      "activitybar": [
        {
          "id": "openrouterChatContainer",
          "title": "OpenRouter",
          "icon": "media/logo.png"
        }
      ]
    },
    "views": {
      "openrouterChatContainer": [
        {
          "id": "openrouterChatView",
          "name": "Chat",
          "type": "webview"
        }
      ]
    },
    "commands": [
      {
        "command": "openrouter.focusChat",
        "title": "Focus AI Chat",
        "category": "AI Assistant"
      },
      {
        "command": "openrouter.clearChat",
        "title": "Clear Chat History",
        "category": "AI Assistant"
      },
      {
        "command": "openrouter.openSettings",
        "title": "AI Assistant Settings",
        "category": "AI Assistant"
      },
      {
        "command": "diffApp.applySolution",
        "title": "Apply Solution from Comments",
        "category": "AI Assistant"
      },
      {
        "command": "diffApp.extractAndApply",
        "title": "Extract and Apply Diff from AI",
        "category": "AI Assistant"
      },
      {
        "command": "diffApp.validateDiff",
        "title": "Validate Diff Syntax",
        "category": "AI Assistant"
      },
      {
        "command": "diffApp.createDiff",
        "title": "Create Diff Between Versions",
        "category": "AI Assistant"
      },
      {
        "command": "diffApp.generateDiff",
        "title": "Generate Git Diff",
        "category": "AI Assistant"
      },
      {
        "command": "openrouter.requestCodeReview",
        "title": "Request Code Review from AI",
        "category": "AI Assistant"
      },
      {
        "command": "openrouter.applyAiSuggestion",
        "title": "Apply Last AI Suggestion",
        "category": "AI Assistant"
      }
    ],
    "configuration": {
      "title": "OpenRouter AI",
      "properties": {
        "openrouter.apiKey": {
          "type": "string",
          "default": "",
          "description": "OpenRouter API key (get from https://openrouter.ai/settings/keys)"
        },
        "openrouter.model": {
          "type": "string",
          "default": "deepseek/deepseek-r1-0528-qwen3-8b",
          "description": "Default AI model to use"
        },
        "openrouter.httpReferer": {
          "type": "string",
          "default": "https://github.com",
          "description": "HTTP Referer for OpenRouter attribution"
        },
        "openrouter.xTitle": {
          "type": "string",
          "default": "OpenRouter VS Code Extension",
          "description": "App title for OpenRouter"
        },
        "openrouter.baseURL": {
          "type": "string",
          "default": "https://openrouter.ai/api/v1",
          "description": "OpenRouter API base URL"
        },
        "openrouter.saveChatHistory": {
          "type": "boolean",
          "default": true,
          "description": "Save chat history between sessions"
        },
        "openrouter.autoApplyDiffs": {
          "type": "boolean",
          "default": false,
          "description": "Auto-apply AI-generated diffs (requires confirmation)"
        },
        "openrouter.saveSuggestionsToHelpFiles": {
          "type": "boolean",
          "default": true,
          "description": "Save AI suggestions to *_help.json files"
        }
      }
    },
    "menus": {
      "editor/context": [
        {
          "command": "diffApp.applySolution",
          "when": "editorTextFocus",
          "group": "ai@1"
        },
        {
          "command": "openrouter.requestCodeReview",
          "when": "editorTextFocus",
          "group": "ai@2"
        },
        {
          "command": "diffApp.extractAndApply",
          "when": "editorHasSelection",
          "group": "ai@3"
        }
      ],
      "command-palette": [
        {
          "command": "openrouter.focusChat"
        },
        {
          "command": "openrouter.clearChat"
        },
        {
          "command": "openrouter.openSettings"
        },
        {
          "command": "diffApp.applySolution"
        },
        {
          "command": "diffApp.validateDiff"
        },
        {
          "command": "openrouter.requestCodeReview"
        }
      ]
    }
  },
  "activationEvents": [
    "onStartupFinished",
    "onCommand:openrouter.focusChat",
    "onCommand:openrouter.clearChat",
    "onCommand:openrouter.openSettings",
    "onCommand:diffApp.applySolution",
    "onCommand:diffApp.extractAndApply",
    "onCommand:diffApp.validateDiff",
    "onCommand:diffApp.createDiff",
    "onCommand:diffApp.generateDiff",
    "onCommand:openrouter.requestCodeReview",
    "onCommand:openrouter.applyAiSuggestion"
  ],
  "categories": [
    "Programming Languages",
    "Snippets",
    "AI",
    "Other"
  ],
  "dependencies": {
    "openai": "^5.23.1"
  }
}
EOL


# ============================================================================
# 2. TSCONFIG.JSON
# ============================================================================

cat << 'EOL' > tsconfig.json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "ES2020",
    "outDir": "out",
    "lib": ["ES2020", "DOM"],
    "sourceMap": true,
    "rootDir": "src",
    "strict": true,
    "types": ["node"]
  },
  "exclude": ["node_modules", ".vscode-test"]
}
EOL


# Create requirements.txt for Python dependencies (if needed)
cat << 'EOL' > requirements.txt
# Python dependencies for OpenRouter Chat extension
# Note: Most functionality uses Node.js/TypeScript
# Python dependencies are optional for advanced features

# OpenAI SDK for Python (if you need Python-side API access)
openai>=1.0.0

# For potential future Python-based features:
python-dotenv>=1.0.0
requests>=2.28.0
EOL


# ============================================================================
# 3. CORE DIFF APPLICATION SYSTEM (From first project, enhanced)
# ============================================================================

cat << 'EOL' > src/diff_application.ts
/**
 * UNIFIED DIFF APPLICATION SYSTEM
 * Enhanced version with AI integration
 */

export interface Comment {
    id: number;
    username: string;
    timestamp: string;
    type: 'request' | 'solution' | 'feedback' | 'ai_suggestion';
    message: string;
    diff?: string;
    status?: 'pending' | 'applied' | 'rejected';
    model?: string;  // Which AI model generated this
    context?: string; // Code context when suggestion was made
}

export interface DiffResult {
    success: boolean;
    appliedLines: number[];
    totalChanges: number;
    errors: string[];
    newContent: string;
    warnings: string[];
    diffApplied?: string; // The diff that was applied
}

export interface AISuggestion {
    id: string;
    timestamp: Date;
    model: string;
    originalQuery: string;
    diff: string;
    explanation: string;
    filePath: string;
    applied: boolean;
}

export class DiffApplicationSystem {
    private lastSuggestion?: AISuggestion;
    
    /**
     * Parse and apply a unified diff to source code
     */
    public applyUnifiedDiff(originalContent: string, diffText: string): DiffResult {
        const result: DiffResult = {
            success: false,
            appliedLines: [],
            totalChanges: 0,
            errors: [],
            newContent: originalContent,
            warnings: [],
            diffApplied: diffText
        };

        try {
            const lines = diffText.split('\n');
            const originalLines = originalContent.split('\n');
            const newLines: string[] = [];
            let originalIndex = 0;
            let lineNumber = 1;
            let inHunk = false;
            let hunkStartOriginal = 0;
            let hunkStartNew = 0;
            let hunkLinesOriginal = 0;
            let hunkLinesNew = 0;
            
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];
                
                // Parse hunk header
                if (line.startsWith('@@')) {
                    const hunkMatch = line.match(/@@ -(\d+),(\d+) \+(\d+),(\d+) @@/);
                    if (hunkMatch) {
                        hunkStartOriginal = parseInt(hunkMatch[1]) - 1;
                        hunkLinesOriginal = parseInt(hunkMatch[2]);
                        hunkStartNew = parseInt(hunkMatch[3]) - 1;
                        hunkLinesNew = parseInt(hunkMatch[4]);
                        inHunk = true;
                        originalIndex = hunkStartOriginal;
                        
                        // Ensure we're at the right position in original
                        while (newLines.length < hunkStartNew) {
                            newLines.push(originalLines[newLines.length] || '');
                        }
                        continue;
                    }
                }
                
                if (!inHunk) {
                    continue;
                }
                
                // Process hunk lines
                if (line.startsWith(' ')) {
                    // Context line - keep original
                    if (originalIndex < originalLines.length && 
                        originalLines[originalIndex] === line.substring(1)) {
                        newLines.push(originalLines[originalIndex]);
                        originalIndex++;
                        lineNumber++;
                    } else {
                        result.warnings.push(`Context mismatch at line ${lineNumber}, but continuing`);
                        // Try to recover by adding the context line anyway
                        newLines.push(line.substring(1));
                        originalIndex++;
                        lineNumber++;
                    }
                } 
                else if (line.startsWith('+')) {
                    // Added line - insert new
                    const addedLine = line.substring(1);
                    newLines.push(addedLine);
                    result.appliedLines.push(lineNumber);
                    result.totalChanges++;
                    lineNumber++;
                } 
                else if (line.startsWith('-')) {
                    // Removed line - skip original
                    if (originalIndex < originalLines.length && 
                        originalLines[originalIndex] === line.substring(1)) {
                        result.appliedLines.push(originalIndex + 1);
                        result.totalChanges++;
                        originalIndex++;
                    } else {
                        result.warnings.push(`Deletion mismatch at original line ${originalIndex + 1}, skipping`);
                        originalIndex++;
                    }
                } 
                else if (line === '\\ No newline at end of file') {
                    continue;
                }
                
                // Check if we've processed all hunk lines
                const linesProcessedInHunk = newLines.length - hunkStartNew;
                const deletionsProcessed = result.appliedLines.filter(l => 
                    l > hunkStartOriginal && l <= hunkStartOriginal + hunkLinesOriginal
                ).length;
                
                if (linesProcessedInHunk >= hunkLinesNew && 
                    (hunkLinesOriginal - deletionsProcessed) <= (originalIndex - hunkStartOriginal)) {
                    inHunk = false;
                }
            }
            
            // Add any remaining original lines
            while (originalIndex < originalLines.length) {
                newLines.push(originalLines[originalIndex]);
                originalIndex++;
            }
            
            result.newContent = newLines.join('\n');
            result.success = result.errors.length === 0;
            
        } catch (error: any) {
            result.errors.push(`Error applying diff: ${error.message}`);
        }
        
        return result;
    }
    
    /**
     * Generate a unified diff between two code versions
     */
    public generateUnifiedDiff(original: string, modified: string, fileName: string = 'file'): string {
        const originalLines = original.split('\n');
        const modifiedLines = modified.split('\n');
        
        const diffLines: string[] = [];
        diffLines.push(`--- a/${fileName}`);
        diffLines.push(`+++ b/${fileName}`);
        
        // Simple diff implementation (for production, use a proper diff library)
        let i = 0, j = 0;
        while (i < originalLines.length || j < modifiedLines.length) {
            if (i < originalLines.length && j < modifiedLines.length && 
                originalLines[i] === modifiedLines[j]) {
                diffLines.push(' ' + originalLines[i]);
                i++;
                j++;
            } else if (j < modifiedLines.length && 
                      (i >= originalLines.length || originalLines[i] !== modifiedLines[j])) {
                diffLines.push('+' + modifiedLines[j]);
                j++;
            } else if (i < originalLines.length && 
                      (j >= modifiedLines.length || originalLines[i] !== modifiedLines[j])) {
                diffLines.push('-' + originalLines[i]);
                i++;
            }
        }
        
        return diffLines.join('\n');
    }
    
    /**
     * Validate a diff before applying
     */
    public validateDiff(diffText: string): { isValid: boolean; errors: string[]; warnings: string[] } {
        const errors: string[] = [];
        const warnings: string[] = [];
        const lines = diffText.split('\n');
        
        if (lines.length === 0) {
            errors.push('Diff is empty');
            return { isValid: false, errors, warnings };
        }
        
        let hasHunk = false;
        let inHunk = false;
        let lineCount = 0;
        let hunkCount = 0;
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            lineCount++;
            
            // Check for valid diff lines
            if (line.startsWith('@@')) {
                const hunkMatch = line.match(/@@ -(\d+),(\d+) \+(\d+),(\d+) @@/);
                if (!hunkMatch) {
                    errors.push(`Invalid hunk header at line ${lineCount}: ${line}`);
                } else {
                    hasHunk = true;
                    inHunk = true;
                    hunkCount++;
                    
                    // Validate hunk numbers
                    const oldStart = parseInt(hunkMatch[1]);
                    const oldLines = parseInt(hunkMatch[2]);
                    const newStart = parseInt(hunkMatch[3]);
                    const newLines = parseInt(hunkMatch[4]);
                    
                    if (oldStart <= 0 || newStart <= 0) {
                        warnings.push(`Hunk ${hunkCount} has questionable start positions`);
                    }
                }
                continue;
            }
            
            if (inHunk) {
                if (!line.startsWith(' ') && !line.startsWith('+') && !line.startsWith('-') && 
                    line !== '\\ No newline at end of file') {
                    warnings.push(`Unusual diff line at line ${lineCount}: ${line.substring(0, 50)}...`);
                }
            }
        }
        
        if (!hasHunk) {
            errors.push('No valid diff hunks found');
        }
        
        if (hunkCount > 10) {
            warnings.push(`Large diff with ${hunkCount} hunks - consider breaking into smaller changes`);
        }
        
        return {
            isValid: errors.length === 0,
            errors,
            warnings
        };
    }
    
    /**
     * Extract diff from AI response text (ENHANCED VERSION)
     */
    public extractDiffFromAIResponse(aiResponse: string): { diff: string; explanation: string } {
        // Look for diff blocks with better parsing
        const diffPatterns = [
            /```(?:diff)?\s*\n([\s\S]*?)\n```/,  // Markdown diff block
            /@@ -[\d,]+ \+[\d,]+ @@[\s\S]*?(?=\n\n|\n$|$)/,  // Raw diff
            /--- a\/.*?\n\+\+\+ b\/.*?\n@@ -[\d,]+ \+[\d,]+ @@[\s\S]*?(?=\n\n|```|$)/  // Full unified diff
        ];
        
        for (const pattern of diffPatterns) {
            const match = aiResponse.match(pattern);
            if (match) {
                const diff = match[1] || match[0];
                // Extract explanation (everything before diff)
                const explanation = aiResponse.substring(0, match.index).trim();
                
                // Clean up the diff
                const cleanedDiff = this.cleanDiff(diff);
                
                return {
                    diff: cleanedDiff,
                    explanation: explanation || 'AI suggested change'
                };
            }
        }
        
        // Try to find code blocks that might contain diffs
        const codeBlocks = aiResponse.match(/```[\s\S]*?```/g);
        if (codeBlocks) {
            for (const block of codeBlocks) {
                if (block.includes('--- a/') || block.includes('@@')) {
                    const cleaned = block.replace(/```(?:diff)?/g, '').trim();
                    return {
                        diff: cleaned,
                        explanation: 'AI code change found in code block'
                    };
                }
            }
        }
        
        return { diff: '', explanation: 'No diff found in AI response' };
    }
    
    /**
     * Clean up a diff (remove markdown, extra whitespace, etc.)
     */
    private cleanDiff(diff: string): string {
        let cleaned = diff.trim();
        
        // Remove markdown code fences if present
        cleaned = cleaned.replace(/^```(?:diff)?\s*/g, '');
        cleaned = cleaned.replace(/```$/g, '');
        
        // Ensure proper line endings
        cleaned = cleaned.replace(/\r\n/g, '\n');
        
        // Remove trailing whitespace from each line
        const lines = cleaned.split('\n');
        const cleanedLines = lines.map(line => line.trimEnd());
        
        return cleanedLines.join('\n');
    }
    
    /**
     * Save AI suggestion to help file
     */
    public saveAISuggestionToHelpFile(
        filePath: string, 
        suggestion: { diff: string; explanation: string; model: string; query: string }
    ): boolean {
        try {
            const fs = require('fs');
            const path = require('path');
            
            const dir = path.dirname(filePath);
            const baseName = path.basename(filePath, path.extname(filePath));
            const ext = path.extname(filePath).substring(1);
            const helpFilePath = path.join(dir, `${baseName}_${ext}_help.json`);
            
            let comments: Comment[] = [];
            
            // Load existing comments if file exists
            if (fs.existsSync(helpFilePath)) {
                const content = fs.readFileSync(helpFilePath, 'utf-8');
                const data = JSON.parse(content);
                comments = data.comments || [];
            }
            
            // Create new AI suggestion comment
            const newComment: Comment = {
                id: comments.length > 0 ? Math.max(...comments.map(c => c.id)) + 1 : 1,
                username: 'AI Assistant',
                timestamp: new Date().toISOString(),
                type: 'ai_suggestion',
                message: suggestion.explanation,
                diff: suggestion.diff,
                status: 'pending',
                model: suggestion.model,
                context: suggestion.query
            };
            
            comments.push(newComment);
            
            // Save back to file
            fs.writeFileSync(
                helpFilePath,
                JSON.stringify({ comments }, null, 2),
                'utf-8'
            );
            
            return true;
        } catch (error) {
            console.error('Failed to save AI suggestion:', error);
            return false;
        }
    }
    
    /**
     * Load comments/suggestions from help file
     */
    public loadCommentsFromHelpFile(filePath: string): Comment[] {
        try {
            const fs = require('fs');
            const path = require('path');
            
            const dir = path.dirname(filePath);
            const baseName = path.basename(filePath, path.extname(filePath));
            const ext = path.extname(filePath).substring(1);
            const helpFilePath = path.join(dir, `${baseName}_${ext}_help.json`);
            
            if (!fs.existsSync(helpFilePath)) {
                return [];
            }
            
            const content = fs.readFileSync(helpFilePath, 'utf-8');
            const data = JSON.parse(content);
            return data.comments || [];
        } catch (error) {
            console.error('Failed to load comments:', error);
            return [];
        }
    }
    
    /**
     * Set last AI suggestion (for quick apply)
     */
    public setLastSuggestion(suggestion: AISuggestion): void {
        this.lastSuggestion = suggestion;
    }
    
    /**
     * Get last AI suggestion
     */
    public getLastSuggestion(): AISuggestion | undefined {
        return this.lastSuggestion;
    }
    
    /**
     * Create patch object for programmatic use
     */
    public parseDiffToPatch(diffText: string): any[] {
        const patches: any[] = [];
        const lines = diffText.split('\n');
        let currentPatch: any = null;
        
        for (const line of lines) {
            if (line.startsWith('@@')) {
                const match = line.match(/@@ -(\d+),(\d+) \+(\d+),(\d+) @@/);
                if (match) {
                    if (currentPatch) {
                        patches.push(currentPatch);
                    }
                    currentPatch = {
                        originalStart: parseInt(match[1]) - 1,
                        originalLength: parseInt(match[2]),
                        newStart: parseInt(match[3]) - 1,
                        newLength: parseInt(match[4]),
                        changes: []
                    };
                }
            } else if (currentPatch) {
                if (line.startsWith('+')) {
                    currentPatch.changes.push({ type: 'add', line: line.substring(1) });
                } else if (line.startsWith('-')) {
                    currentPatch.changes.push({ type: 'delete', line: line.substring(1) });
                } else if (line.startsWith(' ')) {
                    currentPatch.changes.push({ type: 'context', line: line.substring(1) });
                }
            }
        }
        
        if (currentPatch) {
            patches.push(currentPatch);
        }
        
        return patches;
    }
    
    /**
     * Preview diff changes without applying
     */
    public previewDiff(original: string, diffText: string): {
        originalLines: string[];
        newLines: string[];
        changes: Array<{type: 'add' | 'delete' | 'modify'; line: number; content: string}>
    } {
        const result = this.applyUnifiedDiff(original, diffText);
        
        if (!result.success) {
            throw new Error('Cannot preview invalid diff');
        }
        
        const originalLines = original.split('\n');
        const newLines = result.newContent.split('\n');
        const changes: Array<{type: 'add' | 'delete' | 'modify'; line: number; content: string}> = [];
        
        // Simplified change detection for preview
        for (const lineNum of result.appliedLines) {
            if (lineNum <= originalLines.length) {
                changes.push({
                    type: 'modify',
                    line: lineNum,
                    content: newLines[lineNum - 1] || ''
                });
            } else {
                changes.push({
                    type: 'add',
                    line: lineNum,
                    content: newLines[lineNum - 1] || ''
                });
            }
        }
        
        return {
            originalLines,
            newLines,
            changes
        };
    }
}
EOL


# ============================================================================
# 4. MAIN EXTENSION FILE
# ============================================================================

cat << 'EOL' > src/extension.ts
import * as vscode from 'vscode';
import { openrouterPanel } from './webview';
import { DiffApplicationSystem } from './diff_application';

// Global instances
let aiPanel: openrouterPanel | null = null;
let diffSystem: DiffApplicationSystem | null = null;

export function activate(context: vscode.ExtensionContext) {
    console.log('OpenRouter Chat extension activating...');
    
    // Initialize core systems
    diffSystem = new DiffApplicationSystem();
    
    // Create and register the webview provider
    aiPanel = new openrouterPanel(context, diffSystem);
    
    // Register all commands
    const commands = [
        // AI Chat commands
        vscode.commands.registerCommand('openrouter.focusChat', () => {
            vscode.commands.executeCommand('workbench.view.extension.openrouterChatContainer');
        }),
        
        vscode.commands.registerCommand('openrouter.clearChat', () => {
            aiPanel?.clearHistory();
        }),
        
        vscode.commands.registerCommand('openrouter.openSettings', () => {
            aiPanel?.showSettings();
        }),
        
        vscode.commands.registerCommand('openrouter.requestCodeReview', async () => {
            await aiPanel?.requestCodeReview();
        }),
        
        vscode.commands.registerCommand('openrouter.applyAiSuggestion', async () => {
            await aiPanel?.applyLastSuggestion();
        }),
        
        // Diff Application commands (from original system)
        vscode.commands.registerCommand('diffApp.applySolution', async () => {
            await applySolutionFromComments();
        }),
        
        vscode.commands.registerCommand('diffApp.extractAndApply', async () => {
            await extractAndApplyDiffFromAI();
        }),
        
        vscode.commands.registerCommand('diffApp.validateDiff', async () => {
            await validateDiffInEditor();
        }),
        
        vscode.commands.registerCommand('diffApp.createDiff', async () => {
            await createDiffBetweenVersions();
        }),
        
        vscode.commands.registerCommand('diffApp.generateDiff', async () => {
            await generateGitDiff();
        })
    ];
    
    // Add all to subscriptions
    commands.forEach(cmd => context.subscriptions.push(cmd));
    
    // Register webview provider
    context.subscriptions.push(
        vscode.window.registerWebviewViewProvider('openrouterChatView', aiPanel)
    );
    
    console.log('OpenRouter Chat activated successfully!');
}

export async function deactivate() {
    if (aiPanel) {
        await aiPanel.saveOnDeactivate();
    }
    console.log('OpenRouter Chat deactivated');
}

// ============================================================================
// DIFF APPLICATION COMMANDS (Standalone implementations)
// ============================================================================

async function applySolutionFromComments(): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('No active editor found');
        return;
    }
    
    const filePath = editor.document.uri.fsPath;
    
    if (!diffSystem) {
        vscode.window.showErrorMessage('Diff system not initialized');
        return;
    }
    
    const comments = diffSystem.loadCommentsFromHelpFile(filePath);
    const solutions = comments.filter(c => c.diff && (c.type === 'solution' || c.type === 'ai_suggestion'));
    
    if (solutions.length === 0) {
        vscode.window.showInformationMessage('No saved solutions found for this file');
        return;
    }
    
    const items = solutions.map((sol, index) => ({
        label: `${sol.type === 'ai_suggestion' ? '🤖' : '💬'} ${sol.username}: ${sol.message.substring(0, 50)}...`,
        description: sol.model ? `Model: ${sol.model}` : '',
        detail: new Date(sol.timestamp).toLocaleString(),
        solution: sol
    }));
    
    const selected = await vscode.window.showQuickPick(items, {
        placeHolder: 'Select a solution to apply'
    });
    
    if (!selected) {
        return;
    }
    
    const originalContent = editor.document.getText();
    const result = diffSystem.applyUnifiedDiff(originalContent, selected.solution.diff!);
    
    if (result.success) {
        const edit = new vscode.WorkspaceEdit();
        const entireRange = new vscode.Range(
            editor.document.positionAt(0),
            editor.document.positionAt(originalContent.length)
        );
        edit.replace(editor.document.uri, entireRange, result.newContent);
        
        const applied = await vscode.workspace.applyEdit(edit);
        if (applied) {
            vscode.window.showInformationMessage(
                `✅ Solution applied! ${result.totalChanges} changes made.`
            );
            
            // Show summary
            showDiffSummary(result);
        }
    } else {
        vscode.window.showErrorMessage(
            `❌ Failed to apply solution:\n${result.errors.join('\n')}`
        );
    }
}

async function extractAndApplyDiffFromAI(): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('No active editor found');
        return;
    }
    
    const selection = editor.selection;
    const selectedText = selection.isEmpty ? 
        editor.document.getText() : 
        editor.document.getText(selection);
    
    const aiResponse = await vscode.window.showInputBox({
        prompt: 'Paste the AI response containing the diff',
        placeHolder: 'AI response with code changes...',
        value: selectedText,
        ignoreFocusOut: true
    });
    
    if (!aiResponse) {
        return;
    }
    
    if (!diffSystem) {
        vscode.window.showErrorMessage('Diff system not initialized');
        return;
    }
    
    const extracted = diffSystem.extractDiffFromAIResponse(aiResponse);
    if (!extracted.diff) {
        vscode.window.showErrorMessage('No valid diff found in the response');
        return;
    }
    
    const validation = diffSystem.validateDiff(extracted.diff);
    if (!validation.isValid) {
        vscode.window.showErrorMessage(
            `Invalid diff format:\n${validation.errors.join('\n')}`
        );
        return;
    }
    
    const originalContent = selection.isEmpty ? 
        editor.document.getText() : 
        editor.document.getText(selection);
    
    const result = diffSystem.applyUnifiedDiff(originalContent, extracted.diff);
    
    if (result.success) {
        const edit = new vscode.WorkspaceEdit();
        
        if (selection.isEmpty) {
            const entireRange = new vscode.Range(
                editor.document.positionAt(0),
                editor.document.positionAt(originalContent.length)
            );
            edit.replace(editor.document.uri, entireRange, result.newContent);
        } else {
            edit.replace(editor.document.uri, selection, result.newContent);
        }
        
        const applied = await vscode.workspace.applyEdit(edit);
        if (applied) {
            vscode.window.showInformationMessage(
                `✅ Diff applied! ${result.totalChanges} changes made.`
            );
            showDiffSummary(result);
        }
    } else {
        vscode.window.showErrorMessage(
            `❌ Failed to apply diff:\n${result.errors.join('\n')}`
        );
    }
}

async function validateDiffInEditor(): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('No active editor found');
        return;
    }
    
    const diffText = editor.document.getText();
    
    if (!diffSystem) {
        vscode.window.showErrorMessage('Diff system not initialized');
        return;
    }
    
    const validation = diffSystem.validateDiff(diffText);
    
    if (validation.isValid) {
        vscode.window.showInformationMessage(
            `✅ Diff is valid!${validation.warnings.length > 0 ? '\nWarnings: ' + validation.warnings.join(', ') : ''}`
        );
    } else {
        vscode.window.showErrorMessage(
            `❌ Invalid diff:\n${validation.errors.join('\n')}`
        );
    }
}

async function createDiffBetweenVersions(): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('No active editor found');
        return;
    }
    
    const original = editor.document.getText();
    const modified = await vscode.window.showInputBox({
        prompt: 'Paste the modified version',
        placeHolder: 'The modified code...',
        value: original,
        ignoreFocusOut: true
    });
    
    if (!modified) {
        return;
    }
    
    if (!diffSystem) {
        vscode.window.showErrorMessage('Diff system not initialized');
        return;
    }
    
    const fileName = editor.document.fileName.split('/').pop() || 'file';
    const diff = diffSystem.generateUnifiedDiff(original, modified, fileName);
    
    const document = await vscode.workspace.openTextDocument({
        content: diff,
        language: 'diff'
    });
    
    await vscode.window.showTextDocument(document);
    vscode.window.showInformationMessage('✅ Diff generated!');
}

async function generateGitDiff(): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('No active editor found');
        return;
    }
    
    vscode.window.showInformationMessage('Git diff functionality would require git integration');
    // Could be implemented with child_process.exec('git diff')
}

function showDiffSummary(result: any): void {
    const outputChannel = vscode.window.createOutputChannel('Diff Application');
    outputChannel.show();
    outputChannel.appendLine('=== DIFF APPLICATION SUMMARY ===');
    outputChannel.appendLine(`Success: ${result.success ? '✅' : '❌'}`);
    outputChannel.appendLine(`Total changes: ${result.totalChanges}`);
    outputChannel.appendLine(`Applied lines: ${result.appliedLines.join(', ')}`);
    
    if (result.warnings && result.warnings.length > 0) {
        outputChannel.appendLine('Warnings:');
        result.warnings.forEach((warning: string) => outputChannel.appendLine(`  • ${warning}`));
    }
    
    if (result.errors.length > 0) {
        outputChannel.appendLine('Errors:');
        result.errors.forEach((error: string) => outputChannel.appendLine(`  • ${error}`));
    }
}
EOL


# ============================================================================
# 5. WEBVIEW PANEL (Enhanced with diff integration)
# ============================================================================
cat << 'EOL' > src/webview.ts
import * as vscode from 'vscode';
import OpenAI from 'openai';
import { DiffApplicationSystem, type Comment, type AISuggestion } from './diff_application';

interface ChatMessage {
    role: 'user' | 'assistant' | 'system';
    content: string;
    timestamp: Date;
    model?: string;
    containsDiff?: boolean;
    diff?: string;
    explanation?: string;
}

interface ModelInfo {
    id: string;
    name: string;
    provider: string;
    description: string;
}

export class openrouterPanel implements vscode.WebviewViewProvider {
    private static instance: openrouterPanel | null = null;
    private _view?: vscode.WebviewView;
    private _disposables: vscode.Disposable[] = [];
    private chatHistory: ChatMessage[] = [];
    private apiKey: string = '';
    private baseURL: string = 'https://openrouter.ai/api/v1';
    private model: string = 'deepseek/deepseek-r1-0528-qwen3-8b';
    private httpReferer: string = 'https://github.com';
    private xTitle: string = 'OpenRouter Chat VS Code Extension';
    private openai: OpenAI | null = null;
    private abortController: AbortController | null = null;
    private isInitialized: boolean = false;
    private diffSystem: DiffApplicationSystem;
    private lastAISuggestion?: AISuggestion;
    
    // Storage keys
    private readonly CHAT_HISTORY_KEY = 'openrouterChatHistory';
    private readonly SAVE_SETTING_KEY = 'openrouterSaveChatHistory';
    private saveChatHistoryEnabled: boolean = true;
    
    // Popular OpenRouter models - Curated from Official List
    private availableModels: ModelInfo[] = [
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

    constructor(
        private readonly context: vscode.ExtensionContext,
        diffSystem: DiffApplicationSystem
    ) {
        openrouterPanel.instance = this;
        this.diffSystem = diffSystem;
        
        this.loadConfiguration();
        this.loadSaveSetting();
        this.loadChatHistory();
        this.startAutoSave();
    }

    public static getInstance(): openrouterPanel | null {
        return openrouterPanel.instance;
    }

    // ============================================================================
    // DIFF INTEGRATION METHODS
    // ============================================================================

    public async applyDiffFromChat(diff: string, explanation: string): Promise<void> {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }

        // Validate diff first
        const validation = this.diffSystem.validateDiff(diff);
        if (!validation.isValid) {
            vscode.window.showErrorMessage(
                `Invalid diff format:\n${validation.errors.join('\n')}`
            );
            return;
        }

        // Show preview option
        const choice = await vscode.window.showQuickPick(
            [
                { label: '$(eye) Preview changes', description: 'See what will change before applying' },
                { label: '$(check) Apply directly', description: 'Apply the diff immediately' },
                { label: '$(save) Save to help file', description: 'Save for later review' }
            ],
            { placeHolder: 'How would you like to proceed with this diff?' }
        );

        if (!choice) {
            return;
        }

        const originalContent = editor.document.getText();

        if (choice.label.includes('Preview')) {
            await this.previewDiff(originalContent, diff, explanation); // Pass explanation here
            return;
        }

        if (choice.label.includes('Save')) {
            const saved = this.diffSystem.saveAISuggestionToHelpFile(
                editor.document.uri.fsPath,
                {
                    diff,
                    explanation,
                    model: this.model,
                    query: this.getLastUserMessage() || 'AI suggestion'
                }
            );
            
            if (saved) {
                vscode.window.showInformationMessage('✅ AI suggestion saved to help file');
            } else {
                vscode.window.showErrorMessage('Failed to save suggestion');
            }
            return;
        }

        // Apply directly
        const result = this.diffSystem.applyUnifiedDiff(originalContent, diff);
        
        if (result.success) {
            const edit = new vscode.WorkspaceEdit();
            const entireRange = new vscode.Range(
                editor.document.positionAt(0),
                editor.document.positionAt(originalContent.length)
            );
            edit.replace(editor.document.uri, entireRange, result.newContent);
            
            const applied = await vscode.workspace.applyEdit(edit);
            if (applied) {
                vscode.window.showInformationMessage(
                    `✅ Diff applied! ${result.totalChanges} changes made.`
                );
                
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
        } else {
            vscode.window.showErrorMessage(
                `❌ Failed to apply diff:\n${result.errors.join('\n')}`
            );
        }
    }

    public async applyLastSuggestion(): Promise<void> {
        if (!this.lastAISuggestion) {
            vscode.window.showInformationMessage('No recent AI suggestion to apply');
            return;
        }

        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }

        const confirm = await vscode.window.showQuickPick(
            ['Yes', 'No'],
            { placeHolder: `Apply "${this.lastAISuggestion.explanation.substring(0, 50)}..."?` }
        );

        if (confirm !== 'Yes') {
            return;
        }

        const originalContent = editor.document.getText();
        const result = this.diffSystem.applyUnifiedDiff(originalContent, this.lastAISuggestion.diff);
        
        if (result.success) {
            const edit = new vscode.WorkspaceEdit();
            const entireRange = new vscode.Range(
                editor.document.positionAt(0),
                editor.document.positionAt(originalContent.length)
            );
            edit.replace(editor.document.uri, entireRange, result.newContent);
            
            await vscode.workspace.applyEdit(edit);
            vscode.window.showInformationMessage('✅ Last AI suggestion applied!');
        }
    }

    public async requestCodeReview(): Promise<void> {
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
            const userMessage: ChatMessage = {
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

    private async previewDiff(original: string, diff: string, explanation?: string): Promise<void> {
        try {
            const preview = this.diffSystem.previewDiff(original, diff);
            
            // Create a diff view
            const panel = vscode.window.createWebviewPanel(
                'diffPreview',
                'Diff Preview',
                vscode.ViewColumn.Beside,
                { enableScripts: true }
            );

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
                } else {
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
                } else {
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

            panel.webview.onDidReceiveMessage(async message => {
                if (message.command === 'applyDiffFromPreview') {
                    const editor = vscode.window.activeTextEditor;
                    if (editor) {
                        const originalContent = editor.document.getText();
                        const result = this.diffSystem.applyUnifiedDiff(originalContent, diff);
                        
                        if (result.success) {
                            const edit = new vscode.WorkspaceEdit();
                            const entireRange = new vscode.Range(
                                editor.document.positionAt(0),
                                editor.document.positionAt(originalContent.length)
                            );
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

        } catch (error) {
            vscode.window.showErrorMessage(`Failed to preview diff: ${error}`);
        }
    }

    private getLastUserMessage(): string | undefined {
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

    private sendHistoryToWebview() {
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

    private async saveChatHistory(): Promise<void> {
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
        } catch (error) {
            console.error('Failed to save chat history:', error);
        }
    }

    private loadChatHistory() {
        try {
            const saved = this.context.globalState.get<any[]>(this.CHAT_HISTORY_KEY);
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
            } else {
                this.chatHistory = [];
            }
        } catch (error) {
            console.error('Failed to load chat history:', error);
            this.chatHistory = [];
        }
    }

    private loadSaveSetting() {
        try {
            const savedSetting = this.context.globalState.get<boolean>(this.SAVE_SETTING_KEY);
            this.saveChatHistoryEnabled = savedSetting === undefined ? true : savedSetting;
        } catch (error) {
            console.error('Failed to load save setting:', error);
            this.saveChatHistoryEnabled = true;
        }
    }

    private startAutoSave() {
        setInterval(async () => {
            if (this.chatHistory.length > 0) {
                try {
                    await this.saveChatHistory();
                } catch (error) {
                    console.error('Auto-save failed:', error);
                }
            }
        }, 30000);
    }

    private updateSaveSetting(enabled: boolean) {
        this.saveChatHistoryEnabled = enabled;
        this.context.globalState.update(this.SAVE_SETTING_KEY, enabled);
        
        if (!enabled) {
            this.context.globalState.update(this.CHAT_HISTORY_KEY, undefined);
        }
    }

    private loadConfiguration() {
        console.log('🔧 [loadConfiguration] START - Loading configuration...');
        
        try {
            const config = vscode.workspace.getConfiguration('openrouter');
            console.log('📝 [loadConfiguration] Configuration section obtained');
            
            // Log what we're reading
            const apiKey = config.get<string>('apiKey', '');
            const model = config.get<string>('model', 'deepseek/deepseek-r1-0528-qwen3-8b');
            const httpReferer = config.get<string>('httpReferer', 'https://github.com');
            const xTitle = config.get<string>('xTitle', 'OpenRouter Chat VS Code Extension');
            const baseURL = config.get<string>('baseURL', 'https://openrouter.ai/api/v1');
            
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
            } else {
                console.log('⚠️ [loadConfiguration] No API key found in configuration');
            }
            
            console.log('✅ [loadConfiguration] COMPLETE - Configuration loaded');
            
        } catch (error) {
            console.error('❌ [loadConfiguration] ERROR - Failed to load configuration:', error);
            
            if (error instanceof Error) {
                console.error('📋 [loadConfiguration] Error details:', error.message);
            } else {
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

    private async saveConfiguration(config: {
        apiKey: string | null;
        model: string;
        httpReferer?: string;
        xTitle?: string;
        baseURL?: string;
    }) {
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
            const currentApiKey = configSection.get<string>('apiKey', '');
            const currentModel = configSection.get<string>('model', '');
            console.log(`   - apiKey: ${currentApiKey ? '****' + currentApiKey.substring(currentApiKey.length - 4) : '(empty)'}`);
            console.log(`   - model: ${currentModel}`);
            
            // CRITICAL FIX: Only update API key if a new one was provided
            if (config.apiKey !== null) {
                console.log('💾 [saveConfiguration] Updating API key (new value provided)...');
                await configSection.update('apiKey', config.apiKey, vscode.ConfigurationTarget.Global);
                console.log('✅ [saveConfiguration] apiKey saved successfully');
                
                // Update local variable
                this.apiKey = config.apiKey || '';
            } else {
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
                
        } catch (error) {
            console.error('❌ [saveConfiguration] ERROR - Failed to save configuration:', error);
            
            // Type guard for error
            if (error instanceof Error) {
                console.error('📋 [saveConfiguration] Error details:', {
                    name: error.name,
                    message: error.message,
                    stack: error.stack,
                    constructor: error.constructor?.name
                });
            } else {
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
                        } else {
                            console.log('🔗 [saveConfiguration] User cancelled opening settings');
                        }
                    });
                } else if (error.message.includes('permission denied')) {
                    console.log('🔍 [saveConfiguration] Detected: Permission denied');
                    errorMessage = 'Permission denied when trying to save configuration. Please check file permissions for your VS Code settings.';
                } else if (error.message.includes('ENOENT')) {
                    console.log('🔍 [saveConfiguration] Detected: File not found (ENOENT)');
                    errorMessage = 'Settings file not found. VS Code settings directory might be corrupted.';
                } else if (error.message.includes('JSON')) {
                    console.log('🔍 [saveConfiguration] Detected: JSON parsing error');
                    errorMessage = 'JSON error in settings file. The settings file might have syntax errors.';
                }
            } else {
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
                this.apiKey = config.apiKey;
                this.model = config.model;
                this.initializeOpenAI();
                
                vscode.window.showInformationMessage('Configuration saved locally (VS Code settings file issue)');
                
            } catch (fallbackError) {
                console.error('❌ [saveConfiguration] Fallback also failed:', fallbackError);
            }
        }
    }

    private initializeOpenAI() {
        if (!this.apiKey) {
            this.openai = null;
            return;
        }

        try {
            this.openai = new OpenAI({
                apiKey: this.apiKey,
                baseURL: this.baseURL,
                dangerouslyAllowBrowser: true
            });
            console.log('OpenAI client initialized for OpenRouter');
        } catch (error) {
            console.error('Failed to initialize OpenAI client:', error);
            this.openai = null;
        }
    }

    public async saveOnDeactivate(): Promise<void> {
        await this.saveChatHistory();
    }

    public clearHistory() {
        this.chatHistory = [];
        this.context.globalState.update(this.CHAT_HISTORY_KEY, undefined);
        
        if (this._view) {
            this._view.webview.postMessage({
                command: 'historyCleared'
            });
        }
        vscode.window.showInformationMessage('Chat history cleared');
    }

    public showSettings() {
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

    resolveWebviewView(
        webviewView: vscode.WebviewView,
        _context: vscode.WebviewViewResolveContext,
        _token: vscode.CancellationToken
    ) {
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

    private setupMessageHandlers(webviewView: vscode.WebviewView) {
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
            } catch (error) {
                console.error('Error handling message:', error);
                webviewView.webview.postMessage({
                    command: 'error',
                    message: `Failed: ${error}`
                });
            }
        }, null, this._disposables);
    }

    private async saveDiffToHelpFile(diff: string, explanation: string): Promise<void> {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }

        const saved = this.diffSystem.saveAISuggestionToHelpFile(
            editor.document.uri.fsPath,
            {
                diff,
                explanation,
                model: this.model,
                query: this.getLastUserMessage() || 'AI suggestion'
            }
        );
        
        if (saved) {
            vscode.window.showInformationMessage('✅ AI suggestion saved to help file');
            if (this._view) {
                this._view.webview.postMessage({
                    command: 'diffSaved',
                    success: true
                });
            }
        } else {
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

    private async handleChat(content: string, code?: string) {
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

        // Add user message to history - FIXED
        const userMessage: ChatMessage = {
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
                    role: 'system' as const,
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
            
            const response = await this.openai!.chat.completions.create({
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
                    'X-Token-Limit': '200000'  // Request higher limit
                },
                timeout: 120000
            });

            let fullResponse = '';
            let accumulatedChunks: string[] = [];
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
            const assistantMessage: ChatMessage = {
                role: 'assistant',
                content: fullResponse,
                timestamp: new Date(),
                model: this.model,
                containsDiff: containsDiff,
                diff: containsDiff ? extracted.diff : undefined,
                explanation: containsDiff ? extracted.explanation : undefined
            };
            this.chatHistory.push(assistantMessage);
            
            // Save chat history
            this.saveChatHistory();
            
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

        } catch (error: any) {
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
        } finally {
            this.abortController = null;
            this._view.webview.postMessage({ 
                command: 'loading', 
                loading: false 
            });
        }
    }

    private async handleGetActiveCode() {
        if (!this._view) return;

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
        } else {
            this._view.webview.postMessage({
                command: 'error',
                message: 'No active editor found'
            });
        }
    }

    private async addCommentToActiveFile(comment: string, lineNumber?: number) {
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
            if (language === 'python') commentPrefix = '# ';
            else if (language === 'html' || language === 'xml') commentPrefix = '<!-- ';
            else if (language === 'css') commentPrefix = '/* ';
            
            const commentText = `${commentPrefix}${comment}${language === 'css' ? ' */' : language === 'html' || language === 'xml' ? ' -->' : ''}\n`;
            
            let position: vscode.Position;
            if (lineNumber !== undefined) {
                position = new vscode.Position(lineNumber, 0);
            } else {
                position = editor.selection.active;
            }
            
            edit.insert(document.uri, position, commentText);
            
            await vscode.workspace.applyEdit(edit);
            vscode.window.showInformationMessage('Comment added');
        } catch (error) {
            vscode.window.showErrorMessage(`Failed to add comment: ${error}`);
        }
    }

        private getWebviewContent(webview: vscode.Webview): string {
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

    private getNonce(): string {
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
EOL


# ============================================================================
# 6. PYTHON BACKEND (Optional, for complex diff operations)
# ============================================================================

cat << 'EOL' > scripts/diff_processor.py
#!/usr/bin/env python3
"""
Enhanced Diff Processor - Python backend for complex diff operations
"""

import re
import json
import sys
import difflib
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
from enum import Enum

class DiffChangeType(Enum):
    ADD = "add"
    DELETE = "delete"
    MODIFY = "modify"
    CONTEXT = "context"

@dataclass
class DiffChange:
    type: DiffChangeType
    line_number: int
    content: str
    old_content: Optional[str] = None

@dataclass
class DiffHunk:
    original_start: int
    original_length: int
    new_start: int
    new_length: int
    changes: List[DiffChange]

@dataclass
class DiffResult:
    success: bool
    applied_lines: List[int]
    total_changes: int
    errors: List[str]
    warnings: List[str]
    new_content: str
    hunks: List[DiffHunk]
    diff_applied: str

class AISuggestion:
    def __init__(self, diff: str, explanation: str, model: str, query: str):
        self.diff = diff
        self.explanation = explanation
        self.model = model
        self.query = query
        self.timestamp = None
        self.applied = False

class DiffProcessor:
    """Advanced diff processor with AI integration"""
    
    def __init__(self):
        self.hunk_pattern = re.compile(r'^@@ -(\d+),(\d+) \+(\d+),(\d+) @@')
    
    def apply_unified_diff(self, original_content: str, diff_text: str) -> DiffResult:
        """
        Apply a unified diff to original content with robust error handling
        """
        result = DiffResult(
            success=False,
            applied_lines=[],
            total_changes=0,
            errors=[],
            warnings=[],
            new_content=original_content,
            hunks=[],
            diff_applied=diff_text
        )
        
        try:
            lines = diff_text.splitlines()
            original_lines = original_content.splitlines()
            new_lines = []
            
            current_hunk = None
            hunk_changes = []
            
            i = 0
            original_idx = 0
            
            while i < len(lines):
                line = lines[i]
                
                # Check for hunk header
                hunk_match = self.hunk_pattern.match(line)
                if hunk_match:
                    # Save previous hunk if exists
                    if current_hunk:
                        current_hunk.changes = hunk_changes
                        result.hunks.append(current_hunk)
                    
                    # Parse hunk metadata
                    orig_start = int(hunk_match.group(1)) - 1
                    orig_len = int(hunk_match.group(2))
                    new_start = int(hunk_match.group(3)) - 1
                    new_len = int(hunk_match.group(4))
                    
                    current_hunk = DiffHunk(
                        original_start=orig_start,
                        original_length=orig_len,
                        new_start=new_start,
                        new_length=new_len,
                        changes=[]
                    )
                    hunk_changes = []
                    
                    # Align with original content
                    while len(new_lines) < new_start:
                        if original_idx < len(original_lines):
                            new_lines.append(original_lines[original_idx])
                            original_idx += 1
                        else:
                            result.warnings.append(f"Alignment error at hunk start {new_start}")
                    
                    i += 1
                    continue
                
                # Process diff lines within a hunk
                if current_hunk is not None:
                    if line.startswith(' '):
                        # Context line
                        if original_idx < len(original_lines):
                            if original_lines[original_idx] == line[1:]:
                                new_lines.append(original_lines[original_idx])
                                hunk_changes.append(DiffChange(
                                    type=DiffChangeType.CONTEXT,
                                    line_number=original_idx + 1,
                                    content=line[1:]
                                ))
                                original_idx += 1
                            else:
                                result.warnings.append(f"Context mismatch at line {original_idx + 1}")
                        else:
                            result.warnings.append(f"Original file too short at line {original_idx + 1}")
                    
                    elif line.startswith('+'):
                        # Added line
                        added_content = line[1:]
                        new_lines.append(added_content)
                        result.applied_lines.append(len(new_lines))
                        result.total_changes += 1
                        hunk_changes.append(DiffChange(
                            type=DiffChangeType.ADD,
                            line_number=len(new_lines),
                            content=added_content
                        ))
                    
                    elif line.startswith('-'):
                        # Removed line
                        if original_idx < len(original_lines):
                            if original_lines[original_idx] == line[1:]:
                                result.applied_lines.append(original_idx + 1)
                                result.total_changes += 1
                                hunk_changes.append(DiffChange(
                                    type=DiffChangeType.DELETE,
                                    line_number=original_idx + 1,
                                    content=line[1:]
                                ))
                                original_idx += 1
                            else:
                                result.warnings.append(f"Deletion mismatch at line {original_idx + 1}")
                        else:
                            result.warnings.append(f"Original file too short for deletion at line {original_idx + 1}")
                    
                    elif line == '\\ No newline at end of file':
                        pass
                
                i += 1
            
            # Save the last hunk
            if current_hunk:
                current_hunk.changes = hunk_changes
                result.hunks.append(current_hunk)
            
            # Add remaining original lines
            while original_idx < len(original_lines):
                new_lines.append(original_lines[original_idx])
                original_idx += 1
            
            result.new_content = '\n'.join(new_lines)
            result.success = len(result.errors) == 0
            
        except Exception as e:
            result.errors.append(f"Unexpected error: {str(e)}")
        
        return result
    
    def extract_diff_from_ai_response(self, ai_response: str) -> Dict[str, str]:
        """
        Extract diff from AI response with multiple pattern matching
        """
        patterns = [
            r'```(?:diff)?\s*\n([\s\S]*?)\n```',
            r'@@ -[\d,]+ \+[\d,]+ @@[\s\S]*?(?=\n\n|\n$|$)',
            r'--- a/.*?\n\+\+\+ b/.*?\n@@ -[\d,]+ \+[\d,]+ @@[\s\S]*?(?=\n\n|```|$)'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, ai_response, re.DOTALL)
            if match:
                diff = match.group(1) if match.group(1) else match.group(0)
                
                # Extract explanation (text before the diff)
                explanation_start = max(0, match.start() - 200)
                explanation = ai_response[explanation_start:match.start()].strip()
                explanation = explanation[-150:] if len(explanation) > 150 else explanation
                
                return {
                    'diff': self.clean_diff(diff),
                    'explanation': explanation if explanation else 'AI suggested change',
                    'found': True
                }
        
        # Try to find code blocks that might contain diffs
        code_blocks = re.findall(r'```[\s\S]*?```', ai_response)
        for block in code_blocks:
            if '--- a/' in block or '@@' in block:
                diff = re.sub(r'```(?:diff)?', '', block).strip()
                return {
                    'diff': self.clean_diff(diff),
                    'explanation': 'Found in code block',
                    'found': True
                }
        
        return {'diff': '', 'explanation': '', 'found': False}
    
    def clean_diff(self, diff: str) -> str:
        """Clean up a diff string"""
        cleaned = diff.strip()
        cleaned = re.sub(r'^```(?:diff)?\s*', '', cleaned, flags=re.MULTILINE)
        cleaned = re.sub(r'```$', '', cleaned)
        cleaned = re.sub(r'\r\n', '\n', cleaned)
        
        # Remove trailing whitespace from each line
        lines = cleaned.split('\n')
        cleaned_lines = [line.rstrip() for line in lines]
        
        return '\n'.join(cleaned_lines)
    
    def validate_diff(self, diff_text: str) -> Dict[str, Any]:
        """
        Validate diff structure and syntax
        """
        errors = []
        warnings = []
        
        if not diff_text.strip():
            errors.append("Diff text is empty")
            return {"valid": False, "errors": errors, "warnings": warnings}
        
        lines = diff_text.splitlines()
        
        # Check for proper diff headers
        if len(lines) < 2 or not (lines[0].startswith('--- ') and lines[1].startswith('+++ ')):
            warnings.append("Missing or incomplete diff headers")
        
        has_hunks = False
        line_num = 0
        hunk_count = 0
        
        for i, line in enumerate(lines):
            line_num = i + 1
            
            # Skip headers
            if i < 2 and (line.startswith('--- ') or line.startswith('+++ ')):
                continue
            
            # Check hunk headers
            hunk_match = self.hunk_pattern.match(line)
            if hunk_match:
                has_hunks = True
                hunk_count += 1
                
                # Validate hunk numbers
                try:
                    old_start = int(hunk_match.group(1))
                    old_lines = int(hunk_match.group(2))
                    new_start = int(hunk_match.group(3))
                    new_lines = int(hunk_match.group(4))
                    
                    if old_start <= 0 or new_start <= 0:
                        warnings.append(f"Hunk at line {line_num} has questionable start positions")
                    if old_lines <= 0 or new_lines <= 0:
                        warnings.append(f"Hunk at line {line_num} has zero or negative length")
                    
                except ValueError:
                    errors.append(f"Hunk at line {line_num} has invalid numbers")
                continue
            
            # Check diff lines
            if line and not line.startswith((' ', '+', '-', '\\')):
                warnings.append(f"Invalid diff line at line {line_num}: {line[:50]}...")
        
        if not has_hunks:
            errors.append("No valid diff hunks found")
        
        if hunk_count > 10:
            warnings.append(f"Large diff with {hunk_count} hunks - consider breaking into smaller changes")
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings
        }
    
    def create_patch(self, original: str, modified: str, filename: str = "file") -> str:
        """
        Create a unified diff patch between two versions
        """
        original_lines = original.splitlines(keepends=True)
        modified_lines = modified.splitlines(keepends=True)
        
        diff = difflib.unified_diff(
            original_lines,
            modified_lines,
            fromfile=f'a/{filename}',
            tofile=f'b/{filename}',
            lineterm=''
        )
        
        return '\n'.join(diff)
    
    def preview_diff(self, original: str, diff_text: str) -> Dict[str, Any]:
        """
        Preview diff without applying
        """
        result = self.apply_unified_diff(original, diff_text)
        
        if not result.success:
            return {
                'success': False,
                'error': 'Cannot preview invalid diff',
                'errors': result.errors
            }
        
        original_lines = original.split('\n')
        new_lines = result.new_content.split('\n')
        
        changes = []
        for hunk in result.hunks:
            for change in hunk.changes:
                if change.type == DiffChangeType.ADD:
                    changes.append({
                        'type': 'add',
                        'line': change.line_number,
                        'content': change.content
                    })
                elif change.type == DiffChangeType.DELETE:
                    changes.append({
                        'type': 'delete',
                        'line': change.line_number,
                        'content': change.content
                    })
        
        return {
            'success': True,
            'original_lines': original_lines,
            'new_lines': new_lines,
            'changes': changes,
            'total_changes': result.total_changes,
            'hunks': len(result.hunks)
        }

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Enhanced Diff Processor CLI')
    parser.add_argument('command', choices=['apply', 'validate', 'create', 'extract', 'preview'])
    parser.add_argument('--original', help='Original file')
    parser.add_argument('--modified', help='Modified file')
    parser.add_argument('--diff', help='Diff text')
    parser.add_argument('--input', help='Input file or text')
    parser.add_argument('--output', help='Output file')
    
    args = parser.parse_args()
    processor = DiffProcessor()
    
    if args.command == 'apply':
        if not args.original or not args.diff:
            print("Error: --original and --diff required for apply")
            sys.exit(1)
        
        with open(args.original, 'r') as f:
            original = f.read()
        
        result = processor.apply_unified_diff(original, args.diff)
        
        if args.output:
            with open(args.output, 'w') as f:
                f.write(result.new_content)
        
        print(json.dumps({
            'success': result.success,
            'total_changes': result.total_changes,
            'errors': result.errors,
            'warnings': result.warnings
        }, indent=2))
    
    elif args.command == 'validate':
        if not args.diff:
            print("Error: --diff required for validate")
            sys.exit(1)
        
        validation = processor.validate_diff(args.diff)
        print(json.dumps(validation, indent=2))
    
    elif args.command == 'create':
        if not args.original or not args.modified:
            print("Error: --original and --modified required for create")
            sys.exit(1)
        
        with open(args.original, 'r') as f:
            original = f.read()
        
        with open(args.modified, 'r') as f:
            modified = f.read()
        
        filename = args.original.split('/')[-1]
        diff = processor.create_patch(original, modified, filename)
        
        if args.output:
            with open(args.output, 'w') as f:
                f.write(diff)
        else:
            print(diff)
    
    elif args.command == 'extract':
        if not args.input:
            print("Error: --input required for extract")
            sys.exit(1)
        
        with open(args.input, 'r') as f:
            text = f.read()
        
        extracted = processor.extract_diff_from_ai_response(text)
        print(json.dumps(extracted, indent=2))
    
    elif args.command == 'preview':
        if not args.original or not args.diff:
            print("Error: --original and --diff required for preview")
            sys.exit(1)
        
        with open(args.original, 'r') as f:
            original = f.read()
        
        preview = processor.preview_diff(original, args.diff)
        print(json.dumps(preview, indent=2))

if __name__ == '__main__':
    main()
EOL


# ============================================================================
# 7. EXAMPLE FILES
# ============================================================================

# Create example Python file with AI suggestions
cat << 'EOL' > examples/example.py
def calculate_sum(numbers):
    total = 0
    for num in numbers:
        total += num
    return total

def main():
    numbers = [1, 2, 3, 4, 5]
    result = calculate_sum(numbers)
    print(f"Sum: {result}")

if __name__ == "__main__":
    main()
EOL

# Create example help file with AI suggestions
cat << 'EOL' > examples/example_py_help.json
{
  "comments": [
    {
      "id": 1,
      "username": "AI Assistant",
      "timestamp": "2024-01-15T10:30:00Z",
      "type": "ai_suggestion",
      "message": "Add type hints and improve error handling for calculate_sum function",
      "diff": "--- a/example.py\n+++ b/example.py\n@@ -1,8 +1,15 @@\n-def calculate_sum(numbers):\n-    total = 0\n+from typing import List, Union\n+\n+def calculate_sum(numbers: List[Union[int, float]]) -> Union[int, float]:\n+    \"\"\"Calculate the sum of a list of numbers.\"\"\"\n+    if not numbers:\n+        return 0\n+    \n+    total = 0.0\n     for num in numbers:\n         total += num\n     return total",
      "status": "pending",
      "model": "deepseek/deepseek-r1-0528-qwen3-8b",
      "context": "Add type hints and error handling to calculate_sum function"
    },
    {
      "id": 2,
      "username": "AI Assistant",
      "timestamp": "2024-01-15T11:45:00Z",
      "type": "ai_suggestion",
      "message": "Add docstring and improve main function",
      "diff": "--- a/example.py\n+++ b/example.py\n@@ -8,7 +8,12 @@\n     return total\n \n def main():\n+    \"\"\"Main function to demonstrate calculate_sum.\"\"\"\n     numbers = [1, 2, 3, 4, 5]\n     result = calculate_sum(numbers)\n     print(f\"Sum: {result}\")\n+\n+    # Test with empty list\n+    empty_result = calculate_sum([])\n+    print(f\"Empty list sum: {empty_result}\")",
      "status": "pending",
      "model": "deepseek/deepseek-chat",
      "context": "Improve documentation and add more examples"
    }
  ]
}
EOL

# Create example diff file
cat << 'EOL' > examples/example.diff
--- a/example.py
+++ b/example.py
@@ -1,8 +1,15 @@
-def calculate_sum(numbers):
-    total = 0
+from typing import List, Union
+
+def calculate_sum(numbers: List[Union[int, float]]) -> Union[int, float]:
+    """Calculate the sum of a list of numbers."""
+    if not numbers:
+        return 0
+    
+    total = 0.0
     for num in numbers:
         total += num
     return total

 def main():
+    """Main function to demonstrate calculate_sum."""
     numbers = [1, 2, 3, 4, 5]
     result = calculate_sum(numbers)
EOL


# Create README.md file
cat << 'EOL' > README.md
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
EOL



# -----------------------------
# Create License.md (MIT License)
# -----------------------------
cat <<EOL > LICENSE.md
MIT License

Copyright (c) $(date +%Y) Gabriel Majorsky

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EOL

echo -e "${GREEN}✅ OpenRouter extension created in '$EXTNAME'${NC}"
echo ""
echo -e "${YELLOW}📦 Installing dependencies...${NC}"

# ===============================================
# Build and Install Extension
# ===============================================

echo -e "${CYAN}🔨 Building and installing extension...${NC}"

# Set Node options
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export NODE_OPTIONS=--openssl-legacy-provider

echo -e "${YELLOW}Node: $(node -v) | npm: $(npm -v)${NC}"

# Install dependencies
if [ ! -d "node_modules" ]; then
    echo -e "${CYAN}📦 Installing Node dependencies...${NC}"
    npm install
fi

echo -e "${CYAN}📦 Installing Python dependencies...${NC}"
# Create virtual environment
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Compile TypeScript
echo -e "${CYAN}🔨 Compiling TypeScript...${NC}"
npm run compile

# Package extension
echo -e "${CYAN}📦 Packaging extension...${NC}"

if ! command -v vsce &> /dev/null; then
    echo -e "${YELLOW}Installing vsce...${NC}"
    npm install -g vsce
fi

vsce package --allow-missing-repository

VSIX_FILE=$(ls openrouter-chat-*.vsix 2>/dev/null | head -n1)

if [ ! -f "$VSIX_FILE" ]; then
    echo -e "${RED}❌ Failed to package extension${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Extension packaged: $VSIX_FILE${NC}"

# Install extension
echo -e "${CYAN}📥 Installing extension...${NC}"

if command -v code-server &> /dev/null; then
    echo -e "${YELLOW}🔧 Detected code-server environment${NC}"
    code-server --install-extension "$VSIX_FILE" --force
else
    code --install-extension "$VSIX_FILE" --force
fi

# Remove the huge VSIX file
rm -f openrouter-chat-*.vsix

# Show usage instructions
echo ""
echo -e "${MAGENTA}"
echo "╔══════════════════════════════════════════════════╗"
echo "║           OpenRouter Extension Ready!            ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}🚀 Next steps:${NC}"
echo -e "  1. Open VS Code in this folder"
echo -e "  2. Press ${YELLOW}F5${NC} to start debugging"
echo -e "  3. Get your OpenRouter API key from:"
echo -e "     ${GREEN}https://openrouter.ai/settings/keys${NC}"
echo -e "  4. Open the OpenRouter panel in VS Code"
echo -e "  5. Click 'Settings' and enter your API key"
echo -e "  6. Select a model and start chatting!"
echo ""
echo -e "${YELLOW}📚 Available models include:${NC}"
echo -e "  • DeepSeek R1 8B (reasoning)"
echo -e "  • DeepSeek Chat/Coder"
echo -e "  • Google Gemini 2.0 Flash (free tier)"
echo -e "  • Meta Llama 3.3 70B (free tier)"
echo -e "  • Anthropic Claude 3.5 Haiku"
echo -e "  • OpenAI GPT-4o Mini"
echo ""
echo -e "${MAGENTA}✨ Ready to use multiple AI models through OpenRouter!${NC}"