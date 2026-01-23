import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/admin_analytics_model.dart';

class AdminChartWidget extends StatelessWidget {
  final String title;
  final List<dynamic> data;
  final String chartType;
  final double? height;

  const AdminChartWidget({
    super.key,
    required this.title,
    required this.data,
    required this.chartType,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    switch (chartType) {
      case 'revenue':
        return _buildRevenueChart();
      case 'userGrowth':
        return _buildUserGrowthChart();
      case 'orderStatus':
        return _buildOrderStatusChart();
      case 'categorySales':
        return _buildCategorySalesChart();
      default:
        return _buildGenericChart();
    }
  }

  Widget _buildRevenueChart() {
    if (data.isEmpty) return _buildEmptyChart();
    
    final revenueData = data.cast<RevenueData>();
    final maxRevenue = revenueData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    
    if (maxRevenue == 0) return _buildEmptyChart();
    
    // Create line chart data
    final spots = revenueData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.amount);
    }).toList();
    
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (revenueData.length - 1).toDouble(),
          minY: 0,
          maxY: maxRevenue * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxRevenue / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.lightGrey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₱${value.toInt()}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < revenueData.length) {
                    final date = revenueData[value.toInt()].date;
                    final dateParts = date.split('/');
                    final displayDate = dateParts.length > 1 ? dateParts[1] : date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        displayDate,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryGreen,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.primaryGreen,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryGreen.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = revenueData[spot.x.toInt()].date;
                  return LineTooltipItem(
                    '₱${spot.y.toStringAsFixed(0)}\n$date',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    if (data.isEmpty) return _buildEmptyChart();
    
    final userGrowthData = data.cast<UserGrowthData>();
    
    // Group data by date (month)
    final groupedData = <String, Map<String, int>>{};
    for (final item in userGrowthData) {
      if (!groupedData.containsKey(item.date)) {
        groupedData[item.date] = {'buyer': 0, 'farmer': 0};
      }
      groupedData[item.date]![item.userType] = item.count;
    }
    
    final months = groupedData.keys.toList();
    final maxUsers = userGrowthData.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    
    if (maxUsers == 0) return _buildEmptyChart();
    
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxUsers.toDouble() * 1.2,
          minY: 0,
          barGroups: months.asMap().entries.map((entry) {
            final index = entry.key;
            final month = entry.value;
            final buyers = groupedData[month]!['buyer']!;
            final farmers = groupedData[month]!['farmer']!;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: buyers.toDouble(),
                  color: AppTheme.infoBlue,
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: farmers.toDouble(),
                  color: AppTheme.primaryGreen,
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
              barsSpace: 4,
            );
          }).toList(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxUsers / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.lightGrey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        months[value.toInt()],
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = months[group.x.toInt()];
                final type = rodIndex == 0 ? 'Buyers' : 'Farmers';
                return BarTooltipItem(
                  '$type\n${rod.toY.toInt()}\n$month',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    if (data.isEmpty) return _buildEmptyChart();
    
    final orderStatusData = data.cast<OrderStatusData>();
    
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: PieChart(
              PieChartData(
                sections: orderStatusData.map((item) {
                  final color = _getStatusColor(item.status);
                  return PieChartSectionData(
                    value: item.percentage,
                    title: '${item.percentage.toStringAsFixed(0)}%',
                    color: color,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Add touch feedback here if needed
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: orderStatusData.map((item) {
              final color = _getStatusColor(item.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.status}\n${item.count} (${item.percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySalesChart() {
    if (data.isEmpty) return _buildEmptyChart();
    
    final categorySalesData = data.cast<CategorySalesData>();
    // Use productCount instead of sales since sales is always 0
    final maxCount = categorySalesData.map((e) => e.productCount).reduce((a, b) => a > b ? a : b);
    
    if (maxCount == 0) return _buildEmptyChart();
    
    // Color palette for different categories
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.secondaryGreen,
      AppTheme.infoBlue,
      AppTheme.warningOrange,
      Colors.purple.shade400,
    ];
    
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount.toDouble() * 1.1,
          minY: 0,
          barGroups: categorySalesData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = colors[index % colors.length];
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.productCount.toDouble(),
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxCount.toDouble() * 1.1,
                    color: AppTheme.backgroundLight,
                  ),
                ),
              ],
            );
          }).toList(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxCount / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.lightGrey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < categorySalesData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        categorySalesData[value.toInt()].category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = categorySalesData[group.x.toInt()];
                return BarTooltipItem(
                  '${item.category}\n${item.productCount} products',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 300),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }


  Widget _buildGenericChart() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'Chart visualization\nwould appear here',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningOrange;
      case 'confirmed':
        return AppTheme.primaryGreen;
      case 'delivered':
        return AppTheme.successGreen;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }
}