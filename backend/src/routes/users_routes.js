const { authenticateToken } = require('../middleware/auth');
const { getUserProfile, updateUserProfile, uploadAvatar, getUserStats } = require('./users');

async function routes(fastify, options) {
    // 获取用户资料
    fastify.get('/profile', {
        preHandler: authenticateToken
    }, getUserProfile);
    
    // 更新用户资料
    fastify.patch('/profile', {
        preHandler: authenticateToken,
        schema: {
            body: {
                type: 'object',
                properties: {
                    nickname: { type: 'string', minLength: 1, maxLength: 50 },
                    bio: { type: 'string', maxLength: 500 },
                    skills: { type: 'array', items: { type: 'string' } }
                },
                additionalProperties: false
            }
        }
    }, updateUserProfile);
    
    // 上传头像
    fastify.post('/avatar', {
        preHandler: authenticateToken
    }, uploadAvatar);
    
    // 获取用户统计信息
    fastify.get('/stats', {
        preHandler: authenticateToken
    }, getUserStats);
}

module.exports = routes;
