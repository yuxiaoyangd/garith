const { authenticateToken } = require('../middleware/auth');
const path = require('path');
const fs = require('fs');
const { pipeline } = require('stream/promises');

// 上传项目图片
async function uploadProjectImages(request, reply) {
    try {
        const parts = request.files();
        const uploadedImages = [];

        // ??????
        const uploadDir = path.join(__dirname, '../../uploads/projects');
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        const allowedTypes = [
          'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
          'image/webp', 'image/heic', 'image/heif'
        ];

        const uploadedMeta = [];

        for await (const part of parts) {
            if (part.type !== 'file') continue;

            uploadedMeta.push({ type: part.mimetype, name: part.filename });
            if (!allowedTypes.includes(part.mimetype)) {
                console.log('Project image upload rejected - unsupported type:', part.mimetype);
                return reply.code(400).send({ error: 'Only image files are allowed' });
            }

            // ?????
            const ext = path.extname(part.filename);
            const filename = `project_${Date.now()}_${Math.random().toString(36).slice(2, 9)}${ext}`;
            const filepath = path.join(uploadDir, filename);

            // ????
            await pipeline(part.file, fs.createWriteStream(filepath));

            uploadedImages.push(`/uploads/projects/${filename}`);
        }

        console.log('Project images upload - files:', uploadedMeta);

        if (uploadedImages.length === 0) {
            return reply.code(400).send({ error: 'No valid images uploaded' });
        }

        return reply.send({ 
            message: 'Images uploaded successfully',
            images: uploadedImages
        });
    } catch (error) {
        console.error('Project images upload error:', error);
        return reply.code(500).send({ error: 'Failed to upload images' });
    }
}

async function routes(fastify, options) {
    // 上传项目图片
    fastify.post('/project-images', {
        preHandler: authenticateToken
    }, uploadProjectImages);
}

module.exports = routes;
