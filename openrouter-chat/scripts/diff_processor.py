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
