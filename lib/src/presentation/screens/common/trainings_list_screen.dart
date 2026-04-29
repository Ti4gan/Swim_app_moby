import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/training_plan.dart';
import '../../../domain/models/user_role.dart';
import '../../providers/athlete_providers.dart';
import '../../providers/auth_providers.dart';

class TrainingsListScreen extends ConsumerStatefulWidget {
  const TrainingsListScreen({super.key});

  @override
  ConsumerState<TrainingsListScreen> createState() => _TrainingsListScreenState();
}

class _TrainingsListScreenState extends ConsumerState<TrainingsListScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider).valueOrNull;
    final plansState = user?.role == UserRole.coach 
        ? ref.watch(coachPlansProvider) 
        : ref.watch(athletePlansProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('План тренировок'),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalCalendar(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          plansState.when(
            data: (plans) {
              if (plans.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pool, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('На этот день планов нет', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final plan = plans[index];
                      return _buildTrainingCard(context, plan);
                    },
                    childCount: plans.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(child: Text('Ошибка загрузки: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: user?.role == UserRole.coach
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/coach/create-plan'),
              label: const Text('Назначить'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // Показываем 2 недели
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final dayName = DateFormat('E', 'ru').format(date);
          final dayNum = date.day.toString();

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNum,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrainingCard(BuildContext context, TrainingPlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/training/${plan.id}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.blue.shade400, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ВОДА',
                      style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    plan.targetTime,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plan.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${plan.distanceMeters.toInt()} метров', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('Основная серия', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
