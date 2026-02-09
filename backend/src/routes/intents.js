const { authenticateToken } = require('../middleware/auth');

// 提交合作意向
async function submitIntent(fastify, options) {
    const user = options.request.user;
    const { id } = options.params;
    const { offer, expect, contact } = options.body;
    
    // 检查项目是否存在且状态允许接收意向
    const project = fastify.db.prepare('SELECT * FROM projects WHERE id = ?').get(id);
    if (!project) {
        throw fastify.httpErrors.notFound('Project not found');
    }
    
    if (project.status !== 'active') {
        throw fastify.httpErrors.badRequest('Cannot submit intent to paused or closed projects');
    }
    
    // 检查用户是否已经提交过意向
    const existingIntent = fastify.db.prepare(
        'SELECT id FROM intents WHERE project_id = ? AND user_id = ?'
    ).get(id, user.id);
    
    if (existingIntent) {
        throw fastify.httpErrors.badRequest('You have already submitted an intent for this project');
    }
    
    // 不能给自己的项目提交意向
    if (project.owner_id === user.id) {
        throw fastify.httpErrors.badRequest('Cannot submit intent to your own project');
    }
    
    // 插入合作意向
    const result = fastify.db.prepare(`
        INSERT INTO intents (project_id, user_id, offer, expect, contact)
        VALUES (?, ?, ?, ?, ?)
    `).run(id, user.id, offer, expect, contact);
    
    return { 
        id: result.lastInsertRowid,
        message: 'Intent submitted successfully' 
    };
}

// 获取项目的合作意向（仅项目创建者可见）
async function getProjectIntents(fastify, options) {
    const user = options.request.user;
    const { id } = options.params;
    
    // 检查项目是否存在且属于当前用户
    const project = fastify.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);
    
    if (!project) {
        throw fastify.httpErrors.notFound('Project not found or access denied');
    }
    
    const intents = fastify.db.prepare(`
        SELECT i.*, u.nickname, u.email
        FROM intents i
        JOIN users u ON i.user_id = u.id
        WHERE i.project_id = ?
        ORDER BY i.created_at DESC
    `).all(id);
    
    return intents;
}

// 更新意向状态（仅项目创建者）
async function updateIntentStatus(fastify, options) {
    const user = options.request.user;
    const { id, intentId } = options.params;
    const { status } = options.body;
    
    // 检查项目是否存在且属于当前用户
    const project = fastify.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);
    
    if (!project) {
        throw fastify.httpErrors.notFound('Project not found or access denied');
    }
    
    // 检查意向是否存在且属于该项目
    const intent = fastify.db.prepare(
        'SELECT * FROM intents WHERE id = ? AND project_id = ?'
    ).get(intentId, id);
    
    if (!intent) {
        throw fastify.httpErrors.notFound('Intent not found');
    }
    
    // 更新意向状态
    fastify.db.prepare('UPDATE intents SET status = ? WHERE id = ?')
        .run(status, intentId);
    
    return { message: 'Intent status updated successfully' };
}

async function intentRoutes(fastify, options) {
    // 提交合作意向（需要登录）
    fastify.post('/:id', {
        preHandler: authenticateToken,
        schema: {
            params: {
                type: 'object',
                required: ['id'],
                properties: {
                    id: { type: 'integer' }
                }
            },
            body: {
                type: 'object',
                required: ['offer', 'expect', 'contact'],
                properties: {
                    offer: { type: 'string', minLength: 1 },
                    expect: { type: 'string', minLength: 1 },
                    contact: { type: 'string', minLength: 1 }
                }
            }
        }
    }, submitIntent);

    // 获取项目的合作意向（仅项目创建者）
    fastify.get('/:id', {
        preHandler: authenticateToken,
        schema: {
            params: {
                type: 'object',
                required: ['id'],
                properties: {
                    id: { type: 'integer' }
                }
            }
        }
    }, getProjectIntents);

    // 更新意向状态（仅项目创建者）
    fastify.patch('/:id/intents/:intentId', {
        preHandler: authenticateToken,
        schema: {
            params: {
                type: 'object',
                required: ['id', 'intentId'],
                properties: {
                    id: { type: 'integer' },
                    intentId: { type: 'integer' }
                }
            },
            body: {
                type: 'object',
                required: ['status'],
                properties: {
                    status: { type: 'string', enum: ['submitted', 'viewed', 'closed'] }
                }
            }
        }
    }, updateIntentStatus);
}

module.exports = intentRoutes;
