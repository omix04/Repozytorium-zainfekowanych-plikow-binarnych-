#!/usr/bin/env node

/**
 * Tag Infected Files CLI
 * Usage: node tag-infected.js <command> [file-path]
 * Commands:
 *   add <path>    - Tag a file as infected
 *   remove <path> - Remove infection tag
 *   list          - List all infected files
 *   sync          - Generate tags from Firestore data
 */

const fs = require('fs');
const path = require('path');

const METADATA_FILE = path.join(__dirname, 'infected_files.json');

function loadMetadata() {
  if (!fs.existsSync(METADATA_FILE)) {
    return { infected_files: [] };
  }
  try {
    return JSON.parse(fs.readFileSync(METADATA_FILE, 'utf-8'));
  } catch (e) {
    console.error('Error reading metadata:', e.message);
    return { infected_files: [] };
  }
}

function saveMetadata(data) {
  fs.writeFileSync(METADATA_FILE, JSON.stringify(data, null, 2));
}

function addFile(filePath) {
  const workspaceRoot = path.dirname(path.dirname(__dirname));
  const relativePath = path.relative(workspaceRoot, filePath).replace(/\\/g, '/');
  
  let data = loadMetadata();
  if (!data.infected_files.includes(relativePath)) {
    data.infected_files.push(relativePath);
    saveMetadata(data);
    console.log(`✓ Tagged as infected: ${relativePath}`);
  } else {
    console.log(`⚠ Already tagged: ${relativePath}`);
  }
}

function removeFile(filePath) {
  const workspaceRoot = path.dirname(path.dirname(__dirname));
  const relativePath = path.relative(workspaceRoot, filePath).replace(/\\/g, '/');
  
  let data = loadMetadata();
  data.infected_files = data.infected_files.filter(f => f !== relativePath);
  saveMetadata(data);
  console.log(`✓ Removed infection tag: ${relativePath}`);
}

function listFiles() {
  let data = loadMetadata();
  if (data.infected_files.length === 0) {
    console.log('No infected files found');
    return;
  }
  console.log(`\n🚨 Infected Files (${data.infected_files.length}):\n`);
  data.infected_files.forEach((f, i) => {
    console.log(`  ${i + 1}. ${f}`);
  });
  console.log('');
}

function main() {
  const [, , command, ...args] = process.argv;
  
  switch (command) {
    case 'add':
      if (args.length === 0) {
        console.error('Usage: tag-infected.js add <file-path>');
        process.exit(1);
      }
      addFile(args[0]);
      break;
    case 'remove':
      if (args.length === 0) {
        console.error('Usage: tag-infected.js remove <file-path>');
        process.exit(1);
      }
      removeFile(args[0]);
      break;
    case 'list':
      listFiles();
      break;
    default:
      console.error('Unknown command:', command);
      console.error('Commands: add, remove, list');
      process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { addFile, removeFile, listFiles, loadMetadata, saveMetadata };
