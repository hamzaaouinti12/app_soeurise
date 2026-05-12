const http = require('http');

const body = JSON.stringify({
  emailOrUsername: "sarah@example.com",
  password: "Password123!"
});

const req = http.request('http://localhost:4000/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body)
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log("Login response: ", data);
    const result = JSON.parse(data);
    const token = result.data?.token || result.token;
    if (!token) {
        console.log("No token", result);
        return;
    }
    
    // Now get a group id
    http.get('http://localhost:4000/api/community/groups/public', (res2) => {
        let data2 = '';
        res2.on('data', chunk => data2 += chunk);
        res2.on('end', () => {
            const groupsRes = JSON.parse(data2);
            if (!groupsRes.data || !groupsRes.data.groups || groupsRes.data.groups.length === 0) {
                console.log("No groups found.");
                return;
            }
            const groupId = groupsRes.data.groups[0].id;
            console.log("Found group:", groupId);
            
            // Join group first
            const joinReq = http.request(`http://localhost:4000/api/community/groups/${groupId}/join`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            }, (resJoin) => {
                let dataJoin = '';
                resJoin.on('data', chunk => dataJoin += chunk);
                resJoin.on('end', () => {
                    console.log("Join response: ", dataJoin);
                    
                    // Now send message
                    const msgBody = JSON.stringify({ text: "Hello from test script" });
                    const msgReq = http.request(`http://localhost:4000/api/community/groups/${groupId}/messages`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Content-Length': Buffer.byteLength(msgBody),
                            'Authorization': `Bearer ${token}`
                        }
                    }, (resMsg) => {
                        let dataMsg = '';
                        resMsg.on('data', chunk => dataMsg += chunk);
                        resMsg.on('end', () => {
                            console.log("Send message response: ", dataMsg);
                        });
                    });
                    msgReq.write(msgBody);
                    msgReq.end();
                });
            });
            joinReq.end();
        });
    });
  });
});
req.write(body);
req.end();
