const { authenticateToken } = require('../middleware/auth');
const { createNotification } = require('./notifications');

// 提交合作意向
async function submitIntent(request, reply) {
    const user = request.user;
    const { id } = request.params;
    const { offer, expect, contact } = request.body;
    
    const project = request.server.db.prepare('SELECT * FROM projects WHERE id = ?').get(id);
    if (!project) {
        return reply.code(404).send({ error: 'Project not found' });
    }
    
    if (project.status !== 'active') {
        return reply.code(400).send({ error: 'Cannot submit intent to paused or closed projects' });
    }
    
    const existingIntent = request.server.db.prepare(
        'SELECT id FROM intents WHERE project_id = ? AND user_id = ?'
    ).get(id, user.id);
    
    if (existingIntent) {
        return reply.code(400).send({ error: 'You have already submitted an intent for this project' });
    }
    
    if (project.owner_id === user.id) {
        return reply.code(400).send({ error: 'Cannot submit intent to your own project' });
    }
    
    const result = request.server.db.prepare(`
        INSERT INTO intents (project_id, user_id, offer, expect, contact)
        VALUES (?, ?, ?, ?, ?)
    `).run(id, user.id, offer, expect, contact);
    
    // 创建通知给项目所有者
    createNotification(request.server.db, {
        to_user_id: project.owner_id,
        from_user_id: user.id,
        type: 'intent_received',
        title: '新的合作意向',
        content: `${user.nickname || '用户'}对你的项目"${project.title}"发送了合作意向`,
        related_id: result.lastInsertRowid
    });
    
    return reply.send({ 
        id: result.lastInsertRowid,
        message: 'Intent submitted successfully' 
    });
}

// 获取项目的合作意向（仅项目创建者可见）
async function getProjectIntents(request, reply) {
    const user = request.user;
    const { id } = request.params;
    
    const project = request.server.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);
    
    if (!project) {
        return reply.code(404).send({ error: 'Project not found or access denied' });
    }
    
    const intents = request.server.db.prepare(`
        SELECT i.*, u.nickname, u.email
        FROM intents i
        JOIN users u ON i.user_id = u.id
        WHERE i.project_id = ?
        ORDER BY i.created_at DESC
    `).all(id);
    
    return reply.send(intents);
}

// 更新意向状态（仅项目创建者）
async function updateIntentStatus(request, reply) {
    const user = request.user;
    const { id, intentId } = request.params;
    const { status } = request.body;
    
    const project = request.server.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);
    
    if (!project) {
        return reply.code(404).send({ error: 'Project not found or access denied' });
    }
    
    const intent = request.server.db.prepare(
        'SELECT * FROM intents WHERE id = ? AND project_id = ?'
    ).get(intentId, id);
    
    if (!intent) {
        return reply.code(404).send({ error: 'Intent not found' });
    }
    
    request.server.db.prepare('UPDATE intents SET status = ? WHERE id = ?')
        .run(status, intentId);
    
    return reply.send({ message: 'Intent status updated successfully' });
}

// 检查用户是否已提交意向
async function checkUserIntent(request, reply) {
    const user = request.user;
    const { id } = request.params;
    
    const intent = request.server.db.prepare(
        'SELECT id FROM intents WHERE project_id = ? AND user_id = ?'
    ).get(id, user.id);
    
    return reply.send({ hasIntent: !!intent });
}

async function intentRoutes(fastify, options) {
    // 检查用户是否已提交意向（需要登录）
    fastify.get('/:id/check', {
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
    }, checkUserIntent);

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
