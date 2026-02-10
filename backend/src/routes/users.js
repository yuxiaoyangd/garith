const { authenticateToken } = require('../middleware/auth');
const path = require('path');
const fs = require('fs');
const { pipeline } = require('stream/promises');

// 获取用户资料
async function getUserProfile(request, reply) {
    const user = request.user;
    
    const profile = request.server.db.prepare(`
        SELECT id, email, nickname, skills, avatar_url, bio, created_at
        FROM users WHERE id = ?
    `).get(user.id);
    
    if (!profile) {
        return reply.code(404).send({ error: 'User not found' });
    }
    
    return reply.send({
        ...profile,
        skills: profile.skills ? JSON.parse(profile.skills) : []
    });
}

// 更新用户资料
async function updateUserProfile(request, reply) {
    const user = request.user;
    const { nickname, bio, skills } = request.body;
    
    const updates = [];
    const params = [];
    
    if (nickname) {
        updates.push('nickname = ?');
        params.push(nickname);
    }
    
    if (bio !== undefined) {
        updates.push('bio = ?');
        params.push(bio);
    }
    
    if (skills) {
        updates.push('skills = ?');
        params.push(JSON.stringify(skills));
    }
    
    if (updates.length === 0) {
        return reply.code(400).send({ error: 'No fields to update' });
    }
    
    params.push(user.id);
    
    const result = request.server.db.prepare(`
        UPDATE users SET ${updates.join(', ')} WHERE id = ?
    `).run(...params);
    
    if (result.changes === 0) {
        return reply.code(404).send({ error: 'User not found' });
    }
    
    return reply.send({ message: 'Profile updated successfully' });
}

// 上传头像
async function uploadAvatar(request, reply) {
    const user = request.user;
    
    try {
        const data = await request.file();
        
        if (!data) {
            return reply.code(400).send({ error: 'No file uploaded' });
        }

        // 检查文件类型（部分Android机型会上传为application/octet-stream，这里做兜底）
        const allowedMimeTypes = [
            'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
            'image/webp', 'image/heic', 'image/heif',
            'application/octet-stream'
        ];
        const allowedExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'];
        const extFromName = path.extname((data.filename || '').toLowerCase());
        console.log('Avatar upload - mimetype:', data.mimetype, 'filename:', data.filename, 'ext:', extFromName);

        const mimeOk = allowedMimeTypes.includes(data.mimetype);
        const extOk = allowedExts.includes(extFromName);
        if (!mimeOk && !extOk) {
            console.log('Avatar upload rejected - unsupported:', { mimetype: data.mimetype, ext: extFromName });
            return reply.code(400).send({ error: 'Only image files are allowed' });
        }

        // 创建上传目录
        const uploadDir = path.join(__dirname, '../../uploads/avatars');
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        // 生成文件名（若ext为空，默认jpg）
        const ext = extFromName || '.jpg';
        const filename = `avatar_${user.id}_${Date.now()}${ext}`;
        const filepath = path.join(uploadDir, filename);

        // 保存文件
        await pipeline(data.file, fs.createWriteStream(filepath));

        const avatarUrl = `/uploads/avatars/${filename}`;
        
        // 删除旧头像文件
        const oldUser = request.server.db.prepare('SELECT avatar_url FROM users WHERE id = ?').get(user.id);
        if (oldUser && oldUser.avatar_url && oldUser.avatar_url !== avatarUrl) {
            const oldFilePath = path.join(__dirname, '../../', oldUser.avatar_url);
            if (fs.existsSync(oldFilePath)) {
                try {
                    fs.unlinkSync(oldFilePath);
                } catch (err) {
                    console.log('Failed to delete old avatar:', err);
                }
            }
        }
        
        // 更新数据库
        request.server.db.prepare(`
            UPDATE users SET avatar_url = ? WHERE id = ?
        `).run(avatarUrl, user.id);
        
        return reply.send({ 
            message: 'Avatar uploaded successfully',
            avatar_url: avatarUrl 
        });
    } catch (error) {
        console.error('Avatar upload error:', error);
        return reply.code(500).send({ error: 'Failed to upload avatar' });
    }
}

// 获取用户统计信息
async function getUserStats(request, reply) {
    const user = request.user;
    
    const stats = {
        projects: request.server.db.prepare(`
            SELECT COUNT(*) as count FROM projects WHERE owner_id = ? AND status = 'active'
        `).get(user.id).count,
        
        intents: request.server.db.prepare(`
            SELECT COUNT(*) as count FROM intents WHERE user_id = ?
        `).get(user.id).count,
        
        collaborations: request.server.db.prepare(`
            SELECT COUNT(*) as count FROM intents 
            WHERE project_id IN (SELECT id FROM projects WHERE owner_id = ?)
        `).get(user.id).count
    };
    
    return reply.send(stats);
}

module.exports = {
    getUserProfile,
    updateUserProfile,
    uploadAvatar,
    getUserStats
};
