#include "FuncA.h"
#include <cmath>

// Function to calculate the sum of the first n elements of the series
// @param x: Value for which the series is calculated
// @param n: Number of terms to include in the series
double TrigFunction::FuncA(double x, int n) {
    double result = 0.0;
    for (int i = 0; i < n; i++) {
        result += (pow(-1, i) * pow(x, 2 * i + 1)) / (2 * i + 1);
    }
    return result;
}
