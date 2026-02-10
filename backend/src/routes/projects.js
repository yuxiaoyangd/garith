const { authenticateToken } = require('../middleware/auth');

// 获取项目列表
async function getProjects(request, reply) {
    const { field, type, stage, status = 'active', page = 1, limit = 20 } = request.query;
    
    let query = `
        SELECT p.*, u.nickname as owner_nickname, u.email as owner_email
        FROM projects p
        JOIN users u ON p.owner_id = u.id
        WHERE p.status = ?
    `;
    const params = [status];

    if (field) {
        query += ' AND p.field = ?';
        params.push(field);
    }
    if (type) {
        query += ' AND p.type = ?';
        params.push(type);
    }
    if (stage) {
        query += ' AND p.stage = ?';
        params.push(stage);
    }

    // 按更新时间排序，超过30天的自动下沉
    query += ' ORDER BY CASE WHEN p.updated_at < datetime(\'now\', \'-30 days\') THEN 2 ELSE 1 END, p.updated_at DESC';
    
    // 分页
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query += ' LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const projects = request.server.db.prepare(query).all(...params);
    
    return reply.send(projects.map(project => ({
        ...project,
        skills: project.skills ? JSON.parse(project.skills) : []
    })));
}

// 获取项目详情
async function getProjectById(request, reply) {
    const { id } = request.params;
    
    const project = request.server.db.prepare(`
        SELECT p.*, u.nickname as owner_nickname, u.email as owner_email
        FROM projects p
        JOIN users u ON p.owner_id = u.id
        WHERE p.id = ?
    `).get(id);
    
    if (!project) {
        return reply.code(404).send({ error: 'Project not found' });
    }

    // 获取项目进度
    const progress = request.server.db.prepare(`
        SELECT * FROM progress 
        WHERE project_id = ? 
        ORDER BY created_at DESC
    `).all(id);

    return reply.send({
        ...project,
        skills: project.skills ? JSON.parse(project.skills) : [],
        progress
    });
}

// 创建项目
async function createProject(request, reply) {
    const user = request.user;
    const { title, type, field, stage, blocker, help_type, is_public_progress } = request.body;
    
    const result = request.server.db.prepare(`
        INSERT INTO projects (title, type, field, stage, blocker, help_type, is_public_progress, owner_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(title, type, field, stage, blocker || null, help_type || null, (is_public_progress ? 1 : 0), user.id);
    
    return reply.send({ 
        id: result.lastInsertRowid,
        message: 'Project created successfully' 
    });
}

// 更新项目状态
async function updateProjectStatus(request, reply) {
    const user = request.user;
    const { id } = request.params;
    const { status } = request.body;
    
    // 检查项目是否存在且属于当前用户
    const project = request.server.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);
    
    if (!project) {
        return reply.code(404).send({ error: 'Project not found' });
    }
    
    request.server.db.prepare('UPDATE projects SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?')
        .run(status, id);
    
    return reply.send({ message: 'Project status updated successfully' });
}

// 删除项目
async function deleteProject(request, reply) {
    const user = request.user;
    const { id } = request.params;
    
    const result = request.server.db.prepare('DELETE FROM projects WHERE id = ? AND owner_id = ?')
        .run(id, user.id);
        
    if (result.changes === 0) {
        return reply.code(404).send({ error: 'Project not found or unauthorized' });
    }
    
    return reply.send({ message: 'Project deleted successfully' });
}

async function projectRoutes(fastify, options) {
    // 获取项目列表（无需登录）
    fastify.get('/', {
        schema: {
            querystring: {
                type: 'object',
                properties: {
                    field: { type: 'string' },
                    type: { type: 'string', enum: ['需求', '合伙', '外包', '能力'] },
                    stage: { type: 'string', enum: ['想法', '原型', '开发中', '已上线'] },
                    status: { type: 'string', enum: ['active', 'paused', 'closed'] },
                    page: { type: 'integer', minimum: 1 },
                    limit: { type: 'integer', minimum: 1, maximum: 100 }
                }
            }
        }
    }, getProjects);

    // 获取项目详情（无需登录）
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
    }, getProjectById);

    // 创建项目（需要登录）
    fastify.post('/', {
        preHandler: authenticateToken,
        schema: {
            body: {
                type: 'object',
                required: ['title', 'type', 'field', 'stage'],
                properties: {
                    title: { type: 'string', minLength: 1, maxLength: 200 },
                    type: { type: 'string', enum: ['需求', '合伙', '外包', '能力'] },
                    field: { type: 'string', minLength: 1 },
                    stage: { type: 'string', enum: ['想法', '原型', '开发中', '已上线'] },
                    blocker: { type: 'string' },
                    help_type: { type: 'string' },
                    is_public_progress: { type: 'boolean' }
                }
            }
        }
    }, createProject);

    // 更新项目状态（需要登录）
    fastify.patch('/:id/status', {
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
                required: ['status'],
                properties: {
                    status: { type: 'string', enum: ['active', 'paused', 'closed'] }
                }
            }
        }
    }, updateProjectStatus);

    // 删除项目（需要登录）
    fastify.delete('/:id', {
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
    }, deleteProject);
}

module.exports = projectRoutes;
