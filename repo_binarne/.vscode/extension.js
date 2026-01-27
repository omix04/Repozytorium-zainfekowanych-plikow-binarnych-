const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

const infectedDecoration = vscode.window.createTextEditorDecorationType({
  backgroundColor: new vscode.ThemeColor('errorForeground'),
  gutterIconPath: new vscode.ThemeIcon('error'),
  light: {
    backgroundColor: 'rgba(255, 0, 0, 0.2)'
  },
  dark: {
    backgroundColor: 'rgba(255, 0, 0, 0.3)'
  },
  isWholeLine: true,
  borderWidth: '1px',
  borderStyle: 'solid',
  borderColor: new vscode.ThemeColor('errorForeground')
});

let infectedFilesMap = new Map();

function loadInfectedFiles() {
  const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
  if (!workspaceFolder) return;

  const metadataPath = path.join(workspaceFolder.uri.fsPath, '.vscode', 'infected_files.json');
  
  try {
    if (fs.existsSync(metadataPath)) {
      const data = fs.readFileSync(metadataPath, 'utf-8');
      const metadata = JSON.parse(data);
      infectedFilesMap.clear();
      
      if (metadata.infected_files && Array.isArray(metadata.infected_files)) {
        metadata.infected_files.forEach(item => {
          const fullPath = path.join(workspaceFolder.uri.fsPath, item.path || item);
          infectedFilesMap.set(fullPath, true);
        });
      }
      
      updateAllEditors();
    }
  } catch (error) {
    console.error('Error loading infected files metadata:', error);
  }
}

function updateAllEditors() {
  vscode.window.visibleTextEditors.forEach(editor => {
    updateEditorDecorations(editor);
  });
}

function updateEditorDecorations(editor) {
  if (!editor) return;
  
  const filePath = editor.document.uri.fsPath;
  const isInfected = infectedFilesMap.has(filePath);
  
  if (isInfected) {
    const decorationRanges = [new vscode.Range(0, 0, 0, 0)];
    editor.setDecorations(infectedDecoration, decorationRanges);
  } else {
    editor.setDecorations(infectedDecoration, []);
  }
}

function tagFileAsInfected(filePath) {
  const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
  if (!workspaceFolder) return;

  const metadataPath = path.join(workspaceFolder.uri.fsPath, '.vscode', 'infected_files.json');
  let metadata = { infected_files: [] };
  
  try {
    if (fs.existsSync(metadataPath)) {
      const data = fs.readFileSync(metadataPath, 'utf-8');
      metadata = JSON.parse(data);
      if (!metadata.infected_files) metadata.infected_files = [];
    }
  } catch (error) {
    console.error('Error reading metadata:', error);
  }
  
  const relativePath = path.relative(workspaceFolder.uri.fsPath, filePath);
  if (!metadata.infected_files.includes(relativePath)) {
    metadata.infected_files.push(relativePath);
  }
  
  try {
    fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
    infectedFilesMap.set(filePath, true);
    updateAllEditors();
    vscode.window.showInformationMessage(`Tagged as infected: ${path.basename(filePath)}`);
  } catch (error) {
    vscode.window.showErrorMessage('Failed to tag file as infected');
  }
}

function removeInfectionTag(filePath) {
  const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
  if (!workspaceFolder) return;

  const metadataPath = path.join(workspaceFolder.uri.fsPath, '.vscode', 'infected_files.json');
  let metadata = { infected_files: [] };
  
  try {
    if (fs.existsSync(metadataPath)) {
      const data = fs.readFileSync(metadataPath, 'utf-8');
      metadata = JSON.parse(data);
    }
  } catch (error) {
    console.error('Error reading metadata:', error);
    return;
  }
  
  const relativePath = path.relative(workspaceFolder.uri.fsPath, filePath);
  metadata.infected_files = metadata.infected_files.filter(f => f !== relativePath);
  
  try {
    fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
    infectedFilesMap.delete(filePath);
    updateAllEditors();
    vscode.window.showInformationMessage(`Removed infection tag from: ${path.basename(filePath)}`);
  } catch (error) {
    vscode.window.showErrorMessage('Failed to remove infection tag');
  }
}

function showInfectedFiles() {
  if (infectedFilesMap.size === 0) {
    vscode.window.showInformationMessage('No infected files found');
    return;
  }
  
  const items = Array.from(infectedFilesMap.keys()).map(filePath => ({
    label: path.basename(filePath),
    detail: filePath,
    filePath: filePath
  }));
  
  vscode.window.showQuickPick(items, {
    title: `Infected Files (${items.length})`
  }).then(selected => {
    if (selected) {
      vscode.workspace.openTextDocument(selected.filePath).then(doc => {
        vscode.window.showTextDocument(doc);
      });
    }
  });
}

function activate(context) {
  console.log('Infected File Tagger activated');
  
  loadInfectedFiles();
  
  context.subscriptions.push(
    vscode.commands.registerCommand('infectedFileTagger.tagAsInfected', () => {
      const editor = vscode.window.activeTextEditor;
      if (editor) {
        tagFileAsInfected(editor.document.uri.fsPath);
      }
    }),
    
    vscode.commands.registerCommand('infectedFileTagger.removeInfectionTag', () => {
      const editor = vscode.window.activeTextEditor;
      if (editor) {
        removeInfectionTag(editor.document.uri.fsPath);
      }
    }),
    
    vscode.commands.registerCommand('infectedFileTagger.showInfectedFiles', () => {
      showInfectedFiles();
    }),
    
    vscode.window.onDidChangeActiveTextEditor(editor => {
      updateEditorDecorations(editor);
    }),
    
    vscode.workspace.onDidChangeTextDocument(event => {
      const editor = vscode.window.activeTextEditor;
      if (editor && event.document === editor.document) {
        updateEditorDecorations(editor);
      }
    }),
    
    vscode.workspace.onDidSaveTextDocument(document => {
      if (document.uri.fsPath.includes('.vscode/infected_files.json')) {
        loadInfectedFiles();
      }
    })
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
