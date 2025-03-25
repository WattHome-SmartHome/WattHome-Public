import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About This App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WattHome App',
              // style: Theme.of(context).textTheme.headline4,
            ),
            SizedBox(height: 16.0),
            Text(
              'The WattHome app is designed to help you track and manage your energy consumption in real-time. '
              'With a user-friendly interface and customizable alerts, you can stay on top of your energy usage and save on your electricity bills.',
              // style: Theme.of(context).textTheme.bodyText1,
            ),
            SizedBox(height: 16.0),
            Text(
              'Features:',
              // style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8.0),
            Text(
              '- Real-time data updates\n'
              '- Energy consumption tracking\n'
              '- Customizable alerts and notifications\n'
              '- User-friendly interface',
              // style: Theme.of(context).textTheme.bodyText1,
            ),
            Spacer(),
            Center(
              child: Text(
                '© 2023 WattHome. All rights reserved.',
                // style: Theme.of(context).textTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
