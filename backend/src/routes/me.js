const { authenticateToken } = require('../middleware/auth');

// 获取我发布的项目
async function getMyProjects(request, reply) {
    const user = request.user;
    const { status, page = 1, limit = 20 } = request.query;
    
    let query = `
        SELECT p.*, 
               (SELECT COUNT(*) FROM progress WHERE project_id = p.id) as progress_count,
               (SELECT COUNT(*) FROM intents WHERE project_id = p.id) as intents_count
        FROM projects p
        WHERE p.owner_id = ?
    `;
    const params = [user.id];

    if (status) {
        query += ' AND p.status = ?';
        params.push(status);
    }

    query += ' ORDER BY p.updated_at DESC';
    
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

// 获取我提交的合作意向
async function getMyIntents(request, reply) {
    const user = request.user;
    const { status, page = 1, limit = 20 } = request.query;
    
    let query = `
        SELECT i.*, 
               p.title as project_title,
               p.field as project_field,
               p.stage as project_stage,
               u.nickname as project_owner_nickname
        FROM intents i
        JOIN projects p ON i.project_id = p.id
        JOIN users u ON p.owner_id = u.id
        WHERE i.user_id = ?
    `;
    const params = [user.id];

    if (status) {
        query += ' AND i.status = ?';
        params.push(status);
    }

    query += ' ORDER BY i.created_at DESC';
    
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query += ' LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    return reply.send(request.server.db.prepare(query).all(...params));
}

// 获取我收到的合作意向（作为项目创建者）
async function getReceivedIntents(request, reply) {
    const user = request.user;
    const { status, page = 1, limit = 20 } = request.query;
    
    let query = `
        SELECT i.*, 
               p.title as project_title,
               u.nickname as user_nickname,
               u.email as user_email
        FROM intents i
        JOIN projects p ON i.project_id = p.id
        JOIN users u ON i.user_id = u.id
        WHERE p.owner_id = ?
    `;
    const params = [user.id];

    if (status) {
        query += ' AND i.status = ?';
        params.push(status);
    }

    query += ' ORDER BY i.created_at DESC';
    
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query += ' LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    return reply.send(request.server.db.prepare(query).all(...params));
}

// 更新用户资料
async function updateProfile(request, reply) {
    const user = request.user;
    const { nickname, skills } = request.body;
    
    let updateFields = [];
    let params = [];
    
    if (nickname !== undefined) {
        updateFields.push('nickname = ?');
        params.push(nickname);
    }
    
    if (skills !== undefined) {
        updateFields.push('skills = ?');
        params.push(JSON.stringify(skills));
    }
    
    if (updateFields.length === 0) {
        return reply.code(400).send({ error: 'No fields to update' });
    }
    
    params.push(user.id);
    
    request.server.db.prepare(`
        UPDATE users 
        SET ${updateFields.join(', ')}
        WHERE id = ?
    `).run(...params);
    
    return reply.send({ message: 'Profile updated successfully' });
}

// 获取当前用户信息
async function getProfile(request, reply) {
    const user = request.user;
    
    const userProfile = request.server.db.prepare('SELECT * FROM users WHERE id = ?').get(user.id);
    
    if (!userProfile) {
        return reply.code(404).send({ error: 'User not found' });
    }
    
    return reply.send({
        id: userProfile.id,
        email: userProfile.email,
        nickname: userProfile.nickname,
        skills: userProfile.skills ? JSON.parse(userProfile.skills) : [],
        created_at: userProfile.created_at,
        avatar_url: userProfile.avatar_url,
        bio: userProfile.bio
    });
}

async function meRoutes(fastify, options) {
    // 获取我发布的项目
    fastify.get('/projects', {
        preHandler: authenticateToken,
        schema: {
            querystring: {
                type: 'object',
                properties: {
                    status: { type: 'string', enum: ['active', 'paused', 'closed'] },
                    page: { type: 'integer', minimum: 1 },
                    limit: { type: 'integer', minimum: 1, maximum: 100 }
                }
            }
        }
    }, getMyProjects);

    // 获取我提交的合作意向
    fastify.get('/intents', {
        preHandler: authenticateToken,
        schema: {
            querystring: {
                type: 'object',
                properties: {
                    status: { type: 'string', enum: ['submitted', 'viewed', 'closed'] },
                    page: { type: 'integer', minimum: 1 },
                    limit: { type: 'integer', minimum: 1, maximum: 100 }
                }
            }
        }
    }, getMyIntents);

    // 获取我收到的合作意向
    fastify.get('/received-intents', {
        preHandler: authenticateToken,
        schema: {
            querystring: {
                type: 'object',
                properties: {
                    status: { type: 'string', enum: ['submitted', 'viewed', 'closed'] },
                    page: { type: 'integer', minimum: 1 },
                    limit: { type: 'integer', minimum: 1, maximum: 100 }
                }
            }
        }
    }, getReceivedIntents);

    // 获取当前用户信息
    fastify.get('/profile', {
        preHandler: authenticateToken
    }, getProfile);

    // 更新用户资料
    fastify.patch('/profile', {
        preHandler: authenticateToken,
        schema: {
            body: {
                type: 'object',
                properties: {
                    nickname: { type: 'string', minLength: 1, maxLength: 50 },
                    skills: { type: 'array', items: { type: 'string' } }
                }
            }
        }
    }, updateProfile);
}

module.exports = meRoutes;
