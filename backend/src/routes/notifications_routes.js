const { authenticateToken } = require('../middleware/auth');
const { getNotifications, getUnreadCount, markAsRead, markAllAsRead } = require('./notifications');

async function routes(fastify, options) {
    // 获取通知列表
    fastify.get('/', {
        preHandler: authenticateToken,
        schema: {
            querystring: {
                type: 'object',
                properties: {
                    page: { type: 'integer', minimum: 1, default: 1 },
                    limit: { type: 'integer', minimum: 1, maximum: 50, default: 20 },
                    unread_only: { type: 'string', enum: ['true', 'false'], default: 'false' }
                }
            }
        }
    }, getNotifications);
    
    // 获取未读通知数量
    fastify.get('/unread-count', {
        preHandler: authenticateToken
    }, getUnreadCount);
    
    // 标记通知为已读
    fastify.patch('/:id/read', {
        preHandler: authenticateToken,
        schema: {
            params: {
                type: 'object',
                properties: {
                    id: { type: 'integer' }
                },
                required: ['id']
            }
        }
    }, markAsRead);
    
    // 标记所有通知为已读
    fastify.patch('/read-all', {
        preHandler: authenticateToken
    }, markAllAsRead);
}

module.exports = routes;
