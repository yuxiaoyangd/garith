import 'package:flutter/material.dart';
import '../models/project.dart';
import '../screens/project_detail_screen.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (project.images.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      _resolveImageUrl(project.images.first),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.divider,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context, project.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildTag(context, project.field, AppTheme.primary),
                  _buildTag(context, project.type, AppTheme.secondary),
                  _buildTag(context, project.stage, AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, 
                        size: 16, 
                        color: Theme.of(context).textTheme.bodySmall?.color
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project.ownerNickname.isNotEmpty 
                            ? project.ownerNickname 
                            : 'Unknown',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if ((project.intentsCount ?? 0) > 0) ...[
                        Icon(Icons.handshake_outlined, 
                          size: 16, 
                          color: AppTheme.primary
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.intentsCount}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String text;
    switch (status) {
      case 'active':
        color = AppTheme.accent;
        text = '进行中';
        break;
      case 'paused':
        color = AppTheme.warning;
        text = '暂停';
        break;
      case 'completed':
        color = AppTheme.textSecondary;
        text = '已完成';
        break;
      default:
        color = AppTheme.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _resolveImageUrl(String value) {
    if (value.startsWith('http')) return value;
    if (value.startsWith('/')) return '${ApiService.baseUrl}$value';
    return '${ApiService.baseUrl}/$value';
  }
}
