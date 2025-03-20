const express = require('express');
const { exec } = require('child_process');
const bodyParser = require('body-parser');
const path = require('path');
const app = express();
const port = 1100;

// Middleware for parsing JSON
app.use(bodyParser.json());

// Serve static files
app.use(express.static(path.join(__dirname)));

// API endpoint to execute commands
app.post('/api/execute', (req, res) => {
    const { command, githubKey, repoName } = req.body;
    
    let cmdToExecute = '';
    
    switch(command) {
        case 'create-repo':
            cmdToExecute = `bash ../bin/initialize ${githubKey} ${repoName}`;
            break;
        case 'push-repo':
            cmdToExecute = `cd ~/manager/manager-web-app && bash ~/manager/bin/push ${githubKey} ${repoName} `;
            break;
        case 'pull-repo':
            cmdToExecute = `cd ~/manager/manager-web-app && bash ~/manager/bin/pull ${githubKey} ${repoName} `;
            break;
        case 'stop-containers':
            cmdToExecute = `cd ~/manager/manager-web-app/${repoName} && bash ~/manager/bin/stop ${githubKey} ${repoName} `;
            break;
        case 'start-containers':
            cmdToExecute = `cd ~/manager/manager-web-app/${repoName} && bash ~/manager/bin/start ${githubKey} ${repoName} `;
            break;
        default:
            return res.status(400).json({ error: 'Invalid command' });
    }
    
    exec(cmdToExecute, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ 
                output: `Error executing command: ${error.message}\n${stderr}` 
            });
        }
        
        res.json({ output: stdout });
    });
});

// Route for the main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Start the server
app.listen(port, () => {
    console.log(`Manager CLI Web Interface running at http://localhost:${port}`);
});
