#!/bin/bash

./hooks/git-format-staged --formatter 'mint run swiftformat --config .swiftformat stdin' 'Sources/*.swift' '!*Generated*'
