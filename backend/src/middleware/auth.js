const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// 验证JWT token
const authenticateToken = (request, reply, done) => {
    const authHeader = request.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return reply.code(401).send({ error: 'Access token required' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return reply.code(403).send({ error: 'Invalid or expired token' });
        }
        request.user = user;
        done();
    });
};

// 生成JWT token
const generateToken = (user) => {
    return jwt.sign(
        { 
            id: user.id, 
            email: user.email,
            nickname: user.nickname 
        },
        JWT_SECRET,
        { expiresIn: '7d' }
    );
};

module.exports = {
    authenticateToken,
    generateToken,
    JWT_SECRET
};
