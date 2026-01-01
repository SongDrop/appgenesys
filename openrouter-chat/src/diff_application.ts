/**
 * UNIFIED DIFF APPLICATION SYSTEM
 * Simple Git-Compatible Patch System
 */

import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

export interface Comment {
    id: number;
    username: string;
    timestamp: string;
    type: 'request' | 'solution' | 'feedback' | 'ai_suggestion';
    message: string;
    diff?: string;
    status?: 'pending' | 'applied' | 'rejected';
    model?: string;
    context?: string;
    patchFile?: string;
    gitCommand?: string;
}

export interface DiffResult {
    success: boolean;
    appliedLines: number[];
    totalChanges: number;
    errors: string[];
    newContent: string;
    warnings: string[];
    diffApplied?: string;
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
    patchFile?: string;
    gitCommand?: string;
}

export interface PatchSaveResult {
    success: boolean;
    patchPath: string;
    gitCommand: string;
    diff: string;
    warnings: string[];
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
                        
                        while (newLines.length < hunkStartNew) {
                            newLines.push(originalLines[newLines.length] || '');
                        }
                        continue;
                    }
                }
                
                if (!inHunk) continue;
                
                if (line.startsWith(' ')) {
                    if (originalIndex < originalLines.length && 
                        originalLines[originalIndex] === line.substring(1)) {
                        newLines.push(originalLines[originalIndex]);
                        originalIndex++;
                        lineNumber++;
                    } else {
                        result.warnings.push(`Context mismatch at line ${lineNumber}`);
                        newLines.push(line.substring(1));
                        originalIndex++;
                        lineNumber++;
                    }
                } 
                else if (line.startsWith('+')) {
                    const addedLine = line.substring(1);
                    newLines.push(addedLine);
                    result.appliedLines.push(lineNumber);
                    result.totalChanges++;
                    lineNumber++;
                } 
                else if (line.startsWith('-')) {
                    if (originalIndex < originalLines.length && 
                        originalLines[originalIndex] === line.substring(1)) {
                        result.appliedLines.push(originalIndex + 1);
                        result.totalChanges++;
                        originalIndex++;
                    } else {
                        result.warnings.push(`Deletion mismatch at line ${originalIndex + 1}`);
                        originalIndex++;
                    }
                } 
                else if (line === '\\ No newline at end of file') {
                    continue;
                }
                
                const linesProcessedInHunk = newLines.length - hunkStartNew;
                const deletionsProcessed = result.appliedLines.filter(l => 
                    l > hunkStartOriginal && l <= hunkStartOriginal + hunkLinesOriginal
                ).length;
                
                if (linesProcessedInHunk >= hunkLinesNew && 
                    (hunkLinesOriginal - deletionsProcessed) <= (originalIndex - hunkStartOriginal)) {
                    inHunk = false;
                }
            }
            
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
    * Get saved patches from workspace
    */
    public getSavedPatches(): Array<{
        relativePath: string;
        explanation: string;
        timestamp: string;
        patchFile: string;
    }> {
        try {
            const workspaceFolders = vscode.workspace.workspaceFolders;
            if (!workspaceFolders || workspaceFolders.length === 0) {
                return [];
            }
            
            const workspaceRoot = workspaceFolders[0].uri.fsPath;
            const allFiles = fs.readdirSync(workspaceRoot);
            const diffFiles = allFiles.filter(file => file.endsWith('.diff'));
            
            return diffFiles.map(file => {
                const filePath = path.join(workspaceRoot, file);
                const stats = fs.statSync(filePath);
                
                // Try to extract explanation from first lines of the file
                let explanation = file.replace('.diff', '').split('.').pop() || 'AI Patch';
                try {
                    const content = fs.readFileSync(filePath, 'utf-8');
                    const lines = content.split('\n');
                    for (const line of lines) {
                        if (line.includes('# Explanation:')) {
                            explanation = line.replace('# Explanation:', '').trim();
                            break;
                        }
                    }
                } catch (e) {
                    // Use default explanation
                }
                
                return {
                    relativePath: file,
                    explanation: explanation,
                    timestamp: stats.mtime.toISOString(),
                    patchFile: filePath
                };
            });
        } catch (error) {
            console.error('Error getting saved patches:', error);
            return [];
        }
    }

    /**
    * Apply patch from file
    */
    public async applyPatchFromFile(patchPath: string): Promise<{ success: boolean; output: string; error: string }> {
        return new Promise((resolve) => {
            const { exec } = require('child_process');
            
            exec(`git apply --3way "${patchPath}"`, (error: any, stdout: string, stderr: string) => {
                if (error) {
                    resolve({
                        success: false,
                        output: stdout,
                        error: stderr || error.message
                    });
                } else {
                    resolve({
                        success: true,
                        output: stdout,
                        error: ''
                    });
                }
            });
        });
    }

    /**
    * Extract and fix diff from AI response with proper file paths
    */
    public extractAndFixDiffFromAIResponse(aiResponse: string, originalFilePath: string): {
        diff: string;
        explanation: string;
        isValid: boolean;
    } {
        const extracted = this.extractDiffFromAIResponse(aiResponse);
        
        if (!extracted.diff) {
            return {
                diff: '',
                explanation: extracted.explanation,
                isValid: false
            };
        }
        
        // Fix the diff headers to use the actual filename
        const fileName = path.basename(originalFilePath);
        const fixedDiff = this.makeGitCompatible(extracted.diff, fileName);
        
        const validation = this.validateDiff(fixedDiff);
        
        return {
            diff: fixedDiff,
            explanation: extracted.explanation,
            isValid: validation.isValid
        };
    }
    
    /**
     * Generate a simple unified diff between two versions
     */
    public generateUnifiedDiff(original: string, modified: string, fileName: string = 'file'): string {
        const originalLines = original.split('\n');
        const modifiedLines = modified.split('\n');
        
        const diffLines: string[] = [];
        diffLines.push(`--- a/${fileName}`);
        diffLines.push(`+++ b/${fileName}`);
        
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
            
            if (line.startsWith('@@')) {
                const hunkMatch = line.match(/@@ -(\d+),(\d+) \+(\d+),(\d+) @@/);
                if (!hunkMatch) {
                    errors.push(`Invalid hunk header at line ${lineCount}: ${line}`);
                } else {
                    hasHunk = true;
                    inHunk = true;
                    hunkCount++;
                    
                    const oldStart = parseInt(hunkMatch[1]);
                    const newStart = parseInt(hunkMatch[3]);
                    
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
            warnings.push(`Large diff with ${hunkCount} hunks`);
        }
        
        return {
            isValid: errors.length === 0,
            errors,
            warnings
        };
    }
    
    /**
     * Extract diff from AI response text
     */
    public extractDiffFromAIResponse(aiResponse: string): { diff: string; explanation: string } {
        const diffPatterns = [
            /```(?:diff)?\s*\n([\s\S]*?)\n```/,  // Markdown diff block
            /@@ -[\d,]+ \+[\d,]+ @@[\s\S]*?(?=\n\n|\n$|$)/,  // Raw diff
            /--- a\/.*?\n\+\+\+ b\/.*?\n@@ -[\d,]+ \+[\d,]+ @@[\s\S]*?(?=\n\n|```|$)/  // Full unified diff
        ];
        
        for (const pattern of diffPatterns) {
            const match = aiResponse.match(pattern);
            if (match) {
                const diff = match[1] || match[0];
                const explanation = aiResponse.substring(0, match.index).trim();
                
                const cleanedDiff = this.cleanDiff(diff);
                
                return {
                    diff: cleanedDiff,
                    explanation: explanation || 'AI suggested change'
                };
            }
        }
        
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
     * Clean up a diff
     */
    private cleanDiff(diff: string): string {
        let cleaned = diff.trim();
        cleaned = cleaned.replace(/^```(?:diff)?\s*/g, '');
        cleaned = cleaned.replace(/```$/g, '');
        cleaned = cleaned.replace(/\r\n/g, '\n');
        
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
            
            if (fs.existsSync(helpFilePath)) {
                const content = fs.readFileSync(helpFilePath, 'utf-8');
                const data = JSON.parse(content);
                comments = data.comments || [];
            }
            
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
     * Save diff as Git-compatible patch in current directory
     */
    public saveAsGitPatch(
        diff: string,
        originalFilePath: string,
        patchName: string,
        model: string = 'unknown',
        query: string = '',
        explanation: string = ''
    ): PatchSaveResult {
        try {
            // Get current workspace directory
            const workspaceFolders = vscode.workspace.workspaceFolders;
            if (!workspaceFolders || workspaceFolders.length === 0) {
                return {
                    success: false,
                    patchPath: '',
                    gitCommand: '',
                    diff: diff,
                    warnings: ['No workspace folder found']
                };
            }
            
            const workspaceRoot = workspaceFolders[0].uri.fsPath;
            
            // Get original filename
            const originalFileName = path.basename(originalFilePath);
            const originalNameNoExt = path.basename(originalFilePath, path.extname(originalFilePath));
            
            // Create safe patch name
            const safePatchName = patchName
                .replace(/[^a-zA-Z0-9_\-.]/g, '-')
                .toLowerCase()
                .substring(0, 50);
            
            // Generate patch filename: originalfile.featurename.diff
            const patchFileName = `${originalNameNoExt}.${safePatchName}.diff`;
            const patchPath = path.join(workspaceRoot, patchFileName);
            
            // Ensure diff has proper Git headers
            const gitCompatibleDiff = this.makeGitCompatible(diff, originalFileName);
            
            // Create metadata header
            const metadata = `# Git-Compatible Patch
# Generated: ${new Date().toISOString()}
# Original file: ${originalFileName}
# Model: ${model}
# Query: ${query.substring(0, 100)}${query.length > 100 ? '...' : ''}
# Explanation: ${explanation}
# 
# Apply with: git apply "${patchFileName}"
# Or: patch -p1 < "${patchFileName}"
#
`;

            // Write patch file
            const fullContent = metadata + '\n' + gitCompatibleDiff;
            fs.writeFileSync(patchPath, fullContent, 'utf-8');
            
            // Generate git command
            const gitCommand = `git apply "${patchFileName}"`;
            
            return {
                success: true,
                patchPath: patchPath,
                gitCommand: gitCommand,
                diff: gitCompatibleDiff,
                warnings: []
            };
            
        } catch (error: any) {
            return {
                success: false,
                patchPath: '',
                gitCommand: '',
                diff: diff,
                warnings: [`Failed to save patch: ${error.message}`]
            };
        }
    }
    
    /**
     * Make diff Git-compatible (ensures proper ---/+++ headers)
     */
    public makeGitCompatible(diffText: string, fileName: string): string {
        const lines = diffText.split('\n');
        
        // Check if already has proper headers
        const hasProperHeaders = lines.some(line => 
            line.startsWith('--- a/') && !line.includes('filename.ext')
        );
        
        if (hasProperHeaders) {
            return diffText;
        }
        
        // Remove any existing incomplete headers
        const contentLines = lines.filter(line => 
            !line.startsWith('--- ') && !line.startsWith('+++ ')
        );
        
        // Add Git-compatible headers
        return `--- a/${fileName}\n+++ b/${fileName}\n${contentLines.join('\n')}`;
    }
    
    /**
     * Apply patch using Git's built-in apply
     */
    public async applyGitPatch(patchPath: string): Promise<{ success: boolean; output: string; error: string }> {
        return new Promise((resolve) => {
            const { exec } = require('child_process');
            
            // Use git apply with 3-way merge for better conflict resolution
            exec(`git apply --3way "${patchPath}"`, (error: any, stdout: string, stderr: string) => {
                if (error) {
                    resolve({
                        success: false,
                        output: stdout,
                        error: stderr || error.message
                    });
                } else {
                    resolve({
                        success: true,
                        output: stdout,
                        error: ''
                    });
                }
            });
        });
    }
    
    /**
     * Validate if patch can be applied with git
     */
    public async checkGitPatch(patchPath: string): Promise<{ canApply: boolean; errors: string[] }> {
        return new Promise((resolve) => {
            const { exec } = require('child_process');
            
            exec(`git apply --check "${patchPath}"`, (error: any) => {
                if (error) {
                    resolve({
                        canApply: false,
                        errors: [error.message]
                    });
                } else {
                    resolve({
                        canApply: true,
                        errors: []
                    });
                }
            });
        });
    }
    
    /**
     * Set last AI suggestion
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
// Key Features:
//     Simple Git-Compatible Patches:
//        Saves as originalfile.featurename.diff in workspace root
//         Includes proper --- a/... and +++ b/... headers
//         Metadata comments with generation info
//
//     Built-in Git Integration:
//         git apply "filename.diff" ready
//         git apply --3way for better conflict handling
//         git apply --check for validation
//
//     Your Workflow:
//     vscode_extension_code_diff_openrouter_api.sh.feature1.diff
//     vscode_extension_code_diff_openrouter_api.sh.feature2.diff
//     git apply vscode_extension_code_diff_openrouter_api.sh.feature1.diff
//
//     Clean & Simple:
//         No hidden .patches/ folder
//         Patches visible in file explorer
//         Easy to manage and version control
//
// Perfect for your LLM workflow! The patches are ready for git apply right after AI generates them. 🚀
