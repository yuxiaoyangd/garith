const { authenticateToken } = require('../middleware/auth');

// 新增项目进度
async function addProgress(fastify, options) {
    const user = options.request.user;
    const { id } = options.params;
    const { content, summary } = options.body;
    
    // 检查项目是否存在且属于当前用户
    const project = fastify.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);
    
    if (!project) {
        throw fastify.httpErrors.notFound('Project not found or access denied');
    }
    
    // 检查项目状态
    if (project.status !== 'active') {
        throw fastify.httpErrors.badRequest('Cannot add progress to paused or closed projects');
    }
    
    // 插入进度记录
    const result = fastify.db.prepare(`
        INSERT INTO progress (project_id, content, summary)
        VALUES (?, ?, ?)
    `).run(id, content, summary);
    
    // 更新项目的updated_at
    fastify.db.prepare('UPDATE projects SET updated_at = CURRENT_TIMESTAMP WHERE id = ?')
        .run(id);
    
    return { 
        id: result.lastInsertRowid,
        message: 'Progress added successfully' 
    };
}

// 获取项目进度（无需登录，但需要项目存在）
async function getProjectProgress(fastify, options) {
    const { id } = options.params;
    
    // 检查项目是否存在
    const project = fastify.db.prepare('SELECT id FROM projects WHERE id = ?').get(id);
    if (!project) {
        throw fastify.httpErrors.notFound('Project not found');
    }
    
    const progress = fastify.db.prepare(`
        SELECT * FROM progress 
        WHERE project_id = ? 
        ORDER BY created_at DESC
    `).all(id);
    
    return progress;
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
