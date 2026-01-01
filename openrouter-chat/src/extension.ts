import * as fs from 'fs';
import * as path from 'path';
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

        vscode.commands.registerCommand('openrouter.applyGitPatch', async (patchPath?: string) => {
            if (!patchPath) {
                // Show quick pick to select patch
                const patches = diffSystem?.getSavedPatches() || [];
                if (patches.length === 0) {
                    vscode.window.showInformationMessage('No saved patches found');
                    return;
                }
                
                const items = patches.map(patch => ({
                    label: `${patch.relativePath} - ${patch.explanation.substring(0, 50)}...`,
                    description: new Date(patch.timestamp).toLocaleString(),
                    detail: `git apply ${patch.relativePath}`,
                    patch: patch  // This is the object with patch properties
                }));
                
                const selected = await vscode.window.showQuickPick(items, {
                    placeHolder: 'Select a patch to apply'
                });
                
                if (!selected) return;
                patchPath = selected.patch.patchFile;  // This should now work
            }
            
            const workspaceFolders = vscode.workspace.workspaceFolders;
            if (!workspaceFolders || workspaceFolders.length === 0) {
                vscode.window.showErrorMessage('No workspace folder found');
                return;
            }
            
            const fullPath = path.join(workspaceFolders[0].uri.fsPath, patchPath);
            
            if (!fs.existsSync(fullPath)) {
                vscode.window.showErrorMessage(`Patch file not found: ${fullPath}`);
                return;
            }
            
            const result = await diffSystem?.applyPatchFromFile(fullPath);
            
            if (result?.success) {
                vscode.window.showInformationMessage('✅ Patch applied successfully!');
                // Refresh the affected file
                const editor = vscode.window.activeTextEditor;
                if (editor) {
                    vscode.commands.executeCommand('workbench.action.files.revert');
                }
            } else {
                vscode.window.showErrorMessage(`❌ Failed to apply patch: ${result?.error || 'Unknown error'}`);
            }
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
