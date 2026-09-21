const ActiveDirectory = require('activedirectory2');

// AD Connection Configuration
const config = {
    url: 'ldap://192.168.17.128',           // Your DC IP Address
    baseDN: 'dc=lab,dc=local',             // Your Domain
    username: 'admin@lab.local',          // Service Account
    password: 'Password123!'
};

const ad = new ActiveDirectory(config);

// Direct live query to Active Directory
app.get('/api/live-users', (req, res) => {
    ad.findUsers((err, users) => {
        if (err) return res.status(500).json(err);
        res.json(users);
    });
});