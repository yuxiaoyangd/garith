const { authenticateToken } = require('../middleware/auth');

// 获取项目列表
async function getProjects(fastify, options) {
    const { field, type, stage, status = 'active', page = 1, limit = 20 } = options.query;
    
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
    query += ' ORDER BY CASE WHEN p.updated_at < datetime("now", "-30 days") THEN 2 ELSE 1 END, p.updated_at DESC';
    
    // 分页
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query += ' LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const projects = fastify.db.prepare(query).all(...params);
    
    // 转换skills字段
    return projects.map(project => ({
        ...project,
        skills: project.skills ? JSON.parse(project.skills) : []
    }));
}

// 获取项目详情
async function getProjectById(fastify, options) {
    const { id } = options.params;
    
    const project = fastify.db.prepare(`
        SELECT p.*, u.nickname as owner_nickname, u.email as owner_email
        FROM projects p
        JOIN users u ON p.owner_id = u.id
        WHERE p.id = ?
    `).get(id);
    
    if (!project) {
        throw fastify.httpErrors.notFound('Project not found');
    }

    // 获取项目进度
    const progress = fastify.db.prepare(`
        SELECT * FROM progress 
        WHERE project_id = ? 
        ORDER BY created_at DESC
    `).all(id);

    return {
        ...project,
        skills: project.skills ? JSON.parse(project.skills) : [],
        progress
    };
}

// 创建项目
async function createProject(fastify, options) {
    const user = options.request.user;
    const { title, type, field, stage, blocker, help_type, is_public_progress } = options.body;
    
    const result = fastify.db.prepare(`
        INSERT INTO projects (title, type, field, stage, blocker, help_type, is_public_progress, owner_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(title, type, field, stage, blocker, help_type, is_public_progress || 1, user.id);
    
    return { 
        id: result.lastInsertRowid,
        message: 'Project created successfully' 
    };
}

// 更新项目状态
async function updateProjectStatus(fastify, options) {
    const user = options.request.user;
    const { id } = options.params;
    const { status } = options.body;
    
    // 检查项目是否存在且属于当前用户
    const project = fastify.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);
    
    if (!project) {
        throw fastify.httpErrors.notFound('Project not found or access denied');
    }
    
    fastify.db.prepare('UPDATE projects SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?')
        .run(status, id);
    
    return { message: 'Project status updated successfully' };
}

async function projectRoutes(fastify, options) {
    // 获取项目列表（无需登录）
    fastify.get('/', {
        schema: {
            querystring: {
                type: 'object',
                properties: {
                    field: { type: 'string' },
                    type: { type: 'string', enum: ['需求', '合伙', '外包'] },
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
                    type: { type: 'string', enum: ['需求', '合伙', '外包'] },
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
}

module.exports = projectRoutes;
