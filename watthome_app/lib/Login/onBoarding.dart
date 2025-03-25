import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../Models/onBoardingModel.dart';
import '../Models/customColors.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({super.key});

  @override
  _OnBoardingState createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  final PageController _pageController = PageController();
  final OnBoardingModel _onBoardingModel = OnBoardingModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Image.asset('assets/Images/Logo&Name.png', height: 50),
              ),
              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {});
                  },
                  itemCount: _onBoardingModel.titles.length,
                  itemBuilder: (context, i) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          _onBoardingModel.images[i],
                          height: 200,
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Text(
                          _onBoardingModel.titles[i],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
                          child: Text(
                            _onBoardingModel.texts[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14,
                                color: CustomColors.textAccentColor),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Smooth Page Indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _onBoardingModel.titles.length,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 8.0,
                    dotWidth: 8.0,
                    activeDotColor: CustomColors.primaryColor,
                    dotColor: CustomColors.primaryAccentColor,
                  ),
                ),
              ),
              // Try Us Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signUp');
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: CustomColors.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Us Out'),
                ),
              ),
              // Sign In Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: CustomColors.primaryColor,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    animationDuration: Duration.zero, // Disable animation
                  ),
                  child: const Text('Sign In'),
                ),
              ),
              // Disclaimer
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'By signing up, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, color: CustomColors.textAccentColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
