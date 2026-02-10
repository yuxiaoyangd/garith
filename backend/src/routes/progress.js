const { authenticateToken } = require('../middleware/auth');

// 新增项目进度
async function addProgress(request, reply) {
    const user = request.user;
    const { id } = request.params;
    const { content, summary } = request.body;
    
    const project = request.server.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);
    
    if (!project) {
        return reply.code(404).send({ error: 'Project not found or access denied' });
    }
    
    if (project.status !== 'active') {
        return reply.code(400).send({ error: 'Cannot add progress to paused or closed projects' });
    }
    
    const result = request.server.db.prepare(`
        INSERT INTO progress (project_id, content, summary)
        VALUES (?, ?, ?)
    `).run(id, content, summary);
    
    request.server.db.prepare('UPDATE projects SET updated_at = CURRENT_TIMESTAMP WHERE id = ?')
        .run(id);
    
    return reply.send({ 
        id: result.lastInsertRowid,
        message: 'Progress added successfully' 
    });
}

// 获取项目进度（无需登录，但需要项目存在）
async function getProjectProgress(request, reply) {
    const { id } = request.params;
    
    const project = request.server.db.prepare('SELECT id FROM projects WHERE id = ?').get(id);
    if (!project) {
        return reply.code(404).send({ error: 'Project not found' });
    }
    
    const progress = request.server.db.prepare(`
        SELECT * FROM progress 
        WHERE project_id = ? 
        ORDER BY created_at DESC
    `).all(id);
    
    return reply.send(progress);
}

async function progressRoutes(fastify, options) {
    // 新增项目进度（需要登录且是项目创建者）
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
                required: ['content'],
                properties: {
                    content: { type: 'string', minLength: 1 },
                    summary: { type: 'string' }
                }
            }
        }
    }, addProgress);

    // 获取项目进度（无需登录）
    fastify.get('/:id', {
        schema: {
            params: {
                type: 'object',
                required: ['id'],
                properties: {
                    id: { type: 'integer' }
                }
            }
        }
    }, getProjectProgress);
}

module.exports = progressRoutes;
