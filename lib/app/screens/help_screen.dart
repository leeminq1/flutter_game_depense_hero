import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게임 가이드')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpCard(
            title: '게임 개요',
            body:
                'PIXEL GUARD:WAVE는 오픈필드 서바이벌 타워 디펜스 게임입니다. 사방에서 몰려오는 적을 막기 위해 타워를 배치하고 방어선을 구축하세요.',
          ),
          _HelpCard(
            title: '기본 플레이',
            body:
                '밝게 표시되는 설치 칸에 타워를 배치하고 웨이브를 시작하세요. 전투 중에도 추가 건설과 업그레이드가 가능하니, 병목 구간과 코너를 중심으로 화력을 모으는 것이 중요합니다.',
          ),
          _HelpCard(
            title: '타워 역할',
            body:
                '궁수는 안정적인 기본 화력, 병영은 길막과 라인 유지, 마법사는 방어력 대응, 빙결은 군중 제어, 금화 방앗간은 경제 지원, 발리스타는 중장갑 처리, 화염 요새는 광역 압박에 강합니다.',
          ),
          _HelpCard(
            title: '적 대응',
            body:
                '빠른 적은 초반에 끊어야 하고, 방패 보병과 중장갑 적은 발리스타나 집중 화력이 필요합니다. 지원형 적은 후열을 강화하므로 버프와 치유를 주는 적부터 우선 제거하는 편이 안전합니다.',
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body),
            ],
          ),
        ),
      ),
    );
  }
}
