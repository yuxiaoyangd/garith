const { authenticateToken } = require('../middleware/auth');

// ????????????
async function getProjects(request, reply) {
    const { field, type, stage, status = 'active', category, page = 1, limit = 20, search } = request.query;
    
    let query = `
        SELECT p.*, u.nickname as owner_nickname, u.email as owner_email
        FROM projects p
        JOIN users u ON p.owner_id = u.id
        WHERE p.status = ?
    `;
    const params = [status];

    // 搜索功能
    if (search) {
        query += ' AND (p.title LIKE ? OR p.blocker LIKE ? OR u.nickname LIKE ?)';
        const searchParam = `%${search}%`;
        params.push(searchParam, searchParam, searchParam);
    }

    if (category === 'ability') {
        query += " AND p.type = '能力'";
    } else if (category === 'project') {
        query += " AND p.type != '能力'";
    }

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
        skills: project.skills ? JSON.parse(project.skills) : [],
        images: project.images ? JSON.parse(project.images) : []
    })));
}

// ????????????
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
        images: project.images ? JSON.parse(project.images) : [],
        progress
    });
}

// 创建项目
async function createProject(request, reply) {
    const user = request.user;
    const { title, type, field, stage, blocker, help_type, is_public_progress, images } = request.body;
    const imagesJson = Array.isArray(images) && images.length > 0 ? JSON.stringify(images) : null;
    
    const result = request.server.db.prepare(`
        INSERT INTO projects (title, type, field, stage, blocker, help_type, is_public_progress, images, owner_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
        title,
        type,
        field,
        stage,
        blocker || null,
        help_type || null,
        (is_public_progress ? 1 : 0),
        imagesJson,
        user.id
    );
    
    return reply.send({ 
        id: result.lastInsertRowid,
        message: 'Project created successfully' 
    });
}

// ??????
// Update project details
async function updateProject(request, reply) {
    const user = request.user;
    const { id } = request.params;
    const {
        title,
        type,
        field,
        stage,
        blocker,
        help_type,
        helpType,
        is_public_progress,
        isPublicProgress,
        images
    } = request.body;

    const project = request.server.db.prepare('SELECT * FROM projects WHERE id = ? AND owner_id = ?')
        .get(id, user.id);

    if (!project) {
        return reply.code(404).send({ error: 'Project not found' });
    }

    const updates = [];
    const params = [];

    if (title !== undefined) {
        updates.push('title = ?');
        params.push(title);
    }
    if (type !== undefined) {
        updates.push('type = ?');
        params.push(type);
    }
    if (field !== undefined) {
        updates.push('field = ?');
        params.push(field);
    }
    if (stage !== undefined) {
        updates.push('stage = ?');
        params.push(stage);
    }
    if (blocker !== undefined) {
        updates.push('blocker = ?');
        params.push(blocker || null);
    }

    const normalizedHelpType = help_type !== undefined ? help_type : helpType;
    if (normalizedHelpType !== undefined) {
        updates.push('help_type = ?');
        params.push(normalizedHelpType || null);
    }

    const normalizedPublicProgress = is_public_progress !== undefined ? is_public_progress : isPublicProgress;
    if (normalizedPublicProgress !== undefined) {
        updates.push('is_public_progress = ?');
        params.push(normalizedPublicProgress ? 1 : 0);
    }

    if (images !== undefined) {
        const imagesJson = Array.isArray(images) && images.length > 0 ? JSON.stringify(images) : null;
        updates.push('images = ?');
        params.push(imagesJson);
    }

    if (updates.length === 0) {
        return reply.code(400).send({ error: 'No fields to update' });
    }

    const updateQuery = `UPDATE projects SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
    params.push(id);
    request.server.db.prepare(updateQuery).run(...params);

    return reply.send({ message: 'Project updated successfully' });
}
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
    // ????????????
    fastify.get('/', {
        schema: {
            querystring: {
                type: 'object',
                properties: {
                    field: { type: 'string' },
                    type: { type: 'string', enum: ['求资', '合伙', '外包', '能力'] },
                    stage: { type: 'string', enum: ['想法', '原型', '开发中', '已上线'] },
                    status: { type: 'string', enum: ['active', 'paused', 'closed'] },
                    page: { type: 'integer', minimum: 1 },
                    limit: { type: 'integer', minimum: 1, maximum: 100 }
                }
            }
        }
    }, getProjects);

    // ????????????
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
                    type: { type: 'string', enum: ['求资', '合伙', '外包', '能力'] },
                    field: { type: 'string', minLength: 1 },
                    stage: { type: 'string', enum: ['想法', '原型', '开发中', '已上线'] },
                    blocker: { type: 'string' },
                    help_type: { type: 'string' },
                    is_public_progress: { type: 'boolean' },
                    images: { type: 'array', items: { type: 'string' } }
                }
            }
        }
    }, createProject);

    // ??????
    // Update project details (requires login)
    fastify.patch('/:id', {
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
                properties: {
                    title: { type: 'string', minLength: 1, maxLength: 200 },
                    type: { type: 'string', enum: ['求资', '合伙', '外包', '能力'] },
                    field: { type: 'string', minLength: 1 },
                    stage: { type: 'string', enum: ['想法', '原型', '开发中', '已上线'] },
                    blocker: { type: 'string' },
                    help_type: { type: 'string' },
                    helpType: { type: 'string' },
                    is_public_progress: { type: 'boolean' },
                    isPublicProgress: { type: 'boolean' },
                    images: { type: 'array', items: { type: 'string' } }
                }
            }
        }
    }, updateProject);
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
