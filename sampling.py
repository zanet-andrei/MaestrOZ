from math import sin, pi

fiveSamples = 0.00011337868

def calcF(semitones):
    return 2**((semitones - 46.0) / 12.0) * 440.0

def sample(i, f, rate):
    return sin(2*3.141*f*i/rate)/2.0

def sampling(i, f, rate):
    acc = 0
    toReturn = []
    while acc < (rate*i):
        toReturn.append(sample(acc, f, rate))
        acc += 1
    return toReturn

def multList(A, factor):
    toReturn = []
    for i in range(len(A)):
        toReturn.append(A[i]*factor)
    return toReturn

def merge(A):
    # A = {3: [1, 2, 3], 4: [1, 2, 3]}
    multA = []
    for key, value in A.items():
        multA.append(multList(value, key))
    mergedA = []
    for i in range(len(multA)):
        for j in range(len(multA[i])):
            try:
                mergedA[j] += multA[i][j]
            except IndexError:
                mergedA.append(multA[i][j])
    return mergedA


print(merge({3: [1, 2, 3], 4: [1, 2, 3]}))
print(calcF(46))

a = [0, 0.0313183, 0.0625135, 0.0934633, 0.124046]
b = [0, 0.0351476, 0.0701213, 0.104748, 0.138857]
c = [0, 0.0186298, 0.0372338, 0.055786, 0.0742608]

for i in range(len(a)):
    print((a[i]+b[i]+c[i])/3)