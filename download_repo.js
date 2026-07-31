const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const repoUrlMain = 'https://github.com/beastdrgo/Smart-Mobile-Based-Driving-Behaviour-Risk-Monitoring-System/archive/refs/heads/main.zip';
const repoUrlMaster = 'https://github.com/beastdrgo/Smart-Mobile-Based-Driving-Behaviour-Risk-Monitoring-System/archive/refs/heads/master.zip';
const zipPath = path.join(__dirname, 'repo.zip');

function download(url, dest, callback) {
  console.log(`Downloading: ${url}`);
  const file = fs.createWriteStream(dest);
  https.get(url, (response) => {
    if (response.statusCode === 302 || response.statusCode === 301) {
      // Follow redirects
      download(response.headers.location, dest, callback);
      return;
    }

    if (response.statusCode !== 200) {
      file.close();
      fs.unlink(dest, () => {});
      callback(new Error(`Failed to download: Status Code ${response.statusCode}`));
      return;
    }

    response.pipe(file);
    file.on('finish', () => {
      file.close(callback);
    });
  }).on('error', (err) => {
    fs.unlink(dest, () => {});
    callback(err);
  });
}

function extractZip() {
  console.log('Extracting archive...');
  try {
    // Windows 10/11 has tar built-in which can extract zip files directly
    execSync(`tar -xf "${zipPath}"`, { stdio: 'inherit' });
    console.log('Extraction completed.');
    return true;
  } catch (err) {
    console.error('Error extracting zip file using tar:', err.message);
    return false;
  }
}

function mergeFolders() {
  console.log('Merging files into project workspace...');
  const dirs = fs.readdirSync(__dirname);
  const repoFolder = dirs.find(d => d.startsWith('Smart-Mobile-Based-Driving-Behaviour-Risk-Monitoring-System-'));
  
  if (!repoFolder) {
    console.error('Could not find extracted folder name.');
    return;
  }

  const sourceDir = path.join(__dirname, repoFolder);
  
  // Recursively copy files from source to destination
  function copyRecursive(src, dest) {
    const exists = fs.existsSync(src);
    const stats = exists && fs.statSync(src);
    const isDirectory = exists && stats.isDirectory();
    
    if (isDirectory) {
      if (!fs.existsSync(dest)) {
        fs.mkdirSync(dest, { recursive: true });
      }
      fs.readdirSync(src).forEach((childItem) => {
        copyRecursive(path.join(src, childItem), path.join(dest, childItem));
      });
    } else {
      fs.copyFileSync(src, dest);
    }
  }

  copyRecursive(sourceDir, __dirname);
  console.log('Workspace files updated successfully.');

  // Clean up
  console.log('Cleaning up temporary files...');
  fs.rmSync(sourceDir, { recursive: true, force: true });
  fs.unlinkSync(zipPath);
  console.log('Cleanup completed.');
}

// Start sequence
download(repoUrlMain, zipPath, (err) => {
  if (err) {
    console.log('Main branch download failed, trying master branch...');
    download(repoUrlMaster, zipPath, (errMaster) => {
      if (errMaster) {
        console.error('Failed to download from both branches:', errMaster.message);
        process.exit(1);
      }
      if (extractZip()) mergeFolders();
    });
  } else {
    if (extractZip()) mergeFolders();
  }
});
