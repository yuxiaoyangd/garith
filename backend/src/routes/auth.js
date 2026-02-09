const nodemailer = require('nodemailer');
const { generateToken } = require('../middleware/auth');

// 验证码存储（生产环境应使用Redis）
const verificationCodes = new Map();

// 邮件发送器配置
const createTransporter = () => {
    if (process.env.NODE_ENV === 'development' && !process.env.SMTP_USER) {
        // 开发环境且未配置邮件服务时返回null
        return null;
    }
    
    return nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.resend.com',
        port: process.env.SMTP_PORT || 587,
        secure: false,
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });
};

// 生成6位验证码
const generateCode = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

// 发送验证码
async function sendVerificationCode(request, reply, fastify) {
    const { email } = request.body;
    
    console.log('Send verification code request for email:', email);
    console.log('Current verification codes:', Array.from(verificationCodes.keys()));
    
    if (!email) {
        return reply.code(400).send({ error: 'Email is required' });
    }

    // 检查发送频率限制
    const lastSent = verificationCodes.get(email)?.timestamp;
    if (lastSent && Date.now() - lastSent < 60000) {
        return reply.code(400).send({ error: 'Please wait 60 seconds before requesting another code' });
    }

    const code = generateCode();
    
    console.log('Generated verification code:', code, 'for email:', email);
    
    // 存储验证码（5分钟有效期）
    verificationCodes.set(email, {
        code,
        timestamp: Date.now(),
        expires: Date.now() + 5 * 60 * 1000
    });
    
    console.log('Verification code stored. Current codes:', Array.from(verificationCodes.keys()));

    try {
        // 使用Resend API发送邮件
        const response = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.SMTP_PASS}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                from: process.env.SMTP_FROM || 'noreply@jianjiemaa.com',
                to: [email],
                subject: 'Garith 验证码',
                text: `您的验证码是：${code}，5分钟内有效。`,
            }),
        });
        
        const responseText = await response.text();
        
        if (!response.ok) {
            console.error('Resend API error details:');
            console.error('Status:', response.status);
            console.error('StatusText:', response.statusText);
            console.error('Response:', responseText);
            
            // 开发环境：邮件发送失败时打印验证码到控制台
            if (process.env.NODE_ENV === 'development') {
                console.log(`\n========== 验证码 ==========`);
                console.log(`邮箱: ${email}`);
                console.log(`验证码: ${code}`);
                console.log(`有效期: 5分钟`);
                console.log(`============================\n`);
            }
            throw new Error(`Resend API error: ${response.statusText}`);
        }
        
        const responseData = JSON.parse(responseText);
        console.log('Resend API success:', responseData);
        
        return reply.send({ message: 'Verification code sent' });
    } catch (error) {
        console.error('Email send error:', error);
        // 开发环境：邮件发送失败时打印验证码到控制台
        if (process.env.NODE_ENV === 'development') {
            console.log(`\n========== 验证码 ==========`);
            console.log(`邮箱: ${email}`);
            console.log(`验证码: ${code}`);
            console.log(`有效期: 5分钟`);
            console.log(`============================\n`);
        }
        return reply.code(500).send({ error: 'Failed to send verification code' });
    }
}

// 验证码登录
async function loginWithCode(request, reply, fastify) {
    const { email, code } = request.body;
    
    console.log('Login attempt:', { email, code });
    console.log('Stored verification codes:', Array.from(verificationCodes.keys()));
    
    if (!email || !code) {
        return reply.code(400).send({ error: 'Email and verification code are required' });
    }

    const storedData = verificationCodes.get(email);
    
    console.log('Stored data for email:', storedData);
    
    if (!storedData) {
        console.log('Verification code not found for email:', email);
        return reply.code(401).send({ error: 'Verification code not found or expired' });
    }

    console.log('Code comparison:', { 
        input: code, 
        stored: storedData.code, 
        match: storedData.code === code 
    });

    if (Date.now() > storedData.expires) {
        console.log('Verification code expired');
        verificationCodes.delete(email);
        return reply.code(401).send({ error: 'Verification code expired' });
    }

    if (storedData.code !== code) {
        console.log('Invalid verification code');
        return reply.code(401).send({ error: 'Invalid verification code' });
    }

    // 验证码正确，清理存储
    verificationCodes.delete(email);

    // 查找或创建用户
    let user = fastify.db.prepare('SELECT * FROM users WHERE email = ?').get(email);
    
    if (!user) {
        // 创建新用户，使用邮箱前缀作为昵称
        const nickname = email.split('@')[0];
        const result = fastify.db.prepare(
            'INSERT INTO users (email, nickname) VALUES (?, ?)'
        ).run(email, nickname);
        
        user = fastify.db.prepare('SELECT * FROM users WHERE id = ?').get(result.lastInsertRowid);
    }

    console.log('User found/created:', user);

    // 生成JWT token
    const token = generateToken(user);

    console.log('Login successful for user:', email);

    return reply.send({
        token,
        user: {
            id: user.id,
            email: user.email,
            nickname: user.nickname,
            skills: user.skills ? JSON.parse(user.skills) : [],
            created_at: user.created_at
        }
    });
}

async function authRoutes(fastify, options) {
    // 发送验证码
    fastify.post('/send-code', {
        schema: {
            body: {
                type: 'object',
                required: ['email'],
                properties: {
                    email: { type: 'string', format: 'email' }
                }
            }
        }
    }, async (request, reply) => {
        return await sendVerificationCode(request, reply, fastify);
    });

    // 验证码登录
    fastify.post('/login', {
        schema: {
            body: {
                type: 'object',
                required: ['email', 'code'],
                properties: {
                    email: { type: 'string', format: 'email' },
                    code: { type: 'string', pattern: '^[0-9]{6}$' }
                }
            }
        }
    }, async (request, reply) => {
        return await loginWithCode(request, reply, fastify);
    });
}

module.exports = authRoutes;
