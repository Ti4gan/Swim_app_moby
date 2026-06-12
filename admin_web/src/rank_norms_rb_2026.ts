export type NormEntry = {
  discipline: string;
  distanceMeters: number;
  poolLengthMeters: number;
  menTimeSec: number;
  womenTimeSec: number;
};

export const RB_2026_SOURCE = 'БФП / ЕВСК, нормативы 2025–2026 (blrswimming.by)';

export const RB_2026_RANK_NORMS: Record<string, NormEntry[]> = {
  "master_of_sport": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 23.4,
      "womenTimeSec": 26.7
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 22.65,
      "womenTimeSec": 25.95
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 51.9,
      "womenTimeSec": 57.9
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 50.4,
      "womenTimeSec": 56.4
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 114.75,
      "womenTimeSec": 127.25
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 111.75,
      "womenTimeSec": 124.25
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 245.0,
      "womenTimeSec": 269.0
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 239.0,
      "womenTimeSec": 263.0
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 50,
      "menTimeSec": 509.0,
      "womenTimeSec": 552.0
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 25,
      "menTimeSec": 497.0,
      "womenTimeSec": 540.0
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 50,
      "menTimeSec": 975.0,
      "womenTimeSec": 1065.0
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 25,
      "menTimeSec": 938.5,
      "womenTimeSec": 1042.5
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 29.2,
      "womenTimeSec": 33.4
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 28.45,
      "womenTimeSec": 32.65
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 64.9,
      "womenTimeSec": 73.9
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 63.4,
      "womenTimeSec": 72.4
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 142.25,
      "womenTimeSec": 158.25
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 139.25,
      "womenTimeSec": 155.25
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 24.9,
      "womenTimeSec": 28.25
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 24.15,
      "womenTimeSec": 27.5
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 55.9,
      "womenTimeSec": 63.4
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 54.4,
      "womenTimeSec": 61.9
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 126.75,
      "womenTimeSec": 140.75
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 123.75,
      "womenTimeSec": 137.75
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 26.2,
      "womenTimeSec": 29.2
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 25.45,
      "womenTimeSec": 28.85
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 58.9,
      "womenTimeSec": 66.4
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 57.4,
      "womenTimeSec": 64.0
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 128.55,
      "womenTimeSec": 141.75
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 125.55,
      "womenTimeSec": 138.75
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 129.75,
      "womenTimeSec": 144.75
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 126.75,
      "womenTimeSec": 141.75
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 277.0,
      "womenTimeSec": 307.0
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 271.0,
      "womenTimeSec": 301.0
    }
  ],
  "candidate_master": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 23.8,
      "womenTimeSec": 27.3
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 54.2,
      "womenTimeSec": 61.7
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 120.5,
      "womenTimeSec": 133.5
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 255.5,
      "womenTimeSec": 279.5
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 25,
      "menTimeSec": 542.5,
      "womenTimeSec": 586.5
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 25,
      "menTimeSec": 1033.5,
      "womenTimeSec": 1170.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 30.3,
      "womenTimeSec": 34.8
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 67.2,
      "womenTimeSec": 78.2
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 149.0,
      "womenTimeSec": 165.0
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 26.5,
      "womenTimeSec": 30.8
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 59.2,
      "womenTimeSec": 67.2
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 130.5,
      "womenTimeSec": 147.0
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 27.8,
      "womenTimeSec": 31.3
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 61.7,
      "womenTimeSec": 69.2
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 132.5,
      "womenTimeSec": 150.5
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 61.7,
      "womenTimeSec": 67.7
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 135.5,
      "womenTimeSec": 152.5
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 289.5,
      "womenTimeSec": 324.0
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 24.8,
      "womenTimeSec": 27.8
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 55.7,
      "womenTimeSec": 62.7
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 122.5,
      "womenTimeSec": 136.0
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 261.5,
      "womenTimeSec": 283.5
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 50,
      "menTimeSec": 553.0,
      "womenTimeSec": 600.0
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 50,
      "menTimeSec": 1052.5,
      "womenTimeSec": 1188.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 31.3,
      "womenTimeSec": 35.3
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 68.7,
      "womenTimeSec": 79.7
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 151.5,
      "womenTimeSec": 168.0
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 26.8,
      "womenTimeSec": 31.3
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 60.7,
      "womenTimeSec": 68.7
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 133.5,
      "womenTimeSec": 150.0
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 28.8,
      "womenTimeSec": 32.3
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 63.7,
      "womenTimeSec": 70.2
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 135.0,
      "womenTimeSec": 153.0
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 138.0,
      "womenTimeSec": 154.5
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 294.0,
      "womenTimeSec": 329.5
    }
  ],
  "first_adult": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 24.8,
      "womenTimeSec": 28.8
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 58.4,
      "womenTimeSec": 65.2
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 129.5,
      "womenTimeSec": 141.5
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 275.5,
      "womenTimeSec": 300.5
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 25,
      "menTimeSec": 573.5,
      "womenTimeSec": 626.0
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 25,
      "menTimeSec": 1097.5,
      "womenTimeSec": 1228.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 31.8,
      "womenTimeSec": 36.3
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 71.2,
      "womenTimeSec": 83.2
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 161.0,
      "womenTimeSec": 176.0
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 27.8,
      "womenTimeSec": 32.8
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 63.2,
      "womenTimeSec": 72.2
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 139.5,
      "womenTimeSec": 156.5
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 30.8,
      "womenTimeSec": 32.8
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 66.7,
      "womenTimeSec": 72.7
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 139.0,
      "womenTimeSec": 159.5
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 66.2,
      "womenTimeSec": 71.7
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 145.5,
      "womenTimeSec": 162.5
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 308.0,
      "womenTimeSec": 344.0
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 25.8,
      "womenTimeSec": 29.3
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 59.7,
      "womenTimeSec": 66.7
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 132.0,
      "womenTimeSec": 144.0
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 281.5,
      "womenTimeSec": 306.0
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 50,
      "menTimeSec": 585.0,
      "womenTimeSec": 637.5
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 50,
      "menTimeSec": 1121.0,
      "womenTimeSec": 1250.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 32.8,
      "womenTimeSec": 37.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 72.2,
      "womenTimeSec": 84.2
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 164.0,
      "womenTimeSec": 179.0
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 28.3,
      "womenTimeSec": 33.3
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 64.7,
      "womenTimeSec": 73.2
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 142.5,
      "womenTimeSec": 160.5
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 30.5,
      "womenTimeSec": 33.5
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 68.2,
      "womenTimeSec": 74.2
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 142.0,
      "womenTimeSec": 163.0
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 148.0,
      "womenTimeSec": 164.0
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 311.5,
      "womenTimeSec": 350.0
    }
  ],
  "second_adult": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 29.8,
      "womenTimeSec": 31.8
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 65.7,
      "womenTimeSec": 71.7
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 146.5,
      "womenTimeSec": 159.0
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 311.5,
      "womenTimeSec": 340.0
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 25,
      "menTimeSec": 633.5,
      "womenTimeSec": 708.5
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 25,
      "menTimeSec": 1231.5,
      "womenTimeSec": 1398.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 35.8,
      "womenTimeSec": 39.3
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 79.7,
      "womenTimeSec": 91.2
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 175.5,
      "womenTimeSec": 194.0
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 31.8,
      "womenTimeSec": 35.3
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 70.2,
      "womenTimeSec": 82.2
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 160.0,
      "womenTimeSec": 181.5
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 32.8,
      "womenTimeSec": 35.3
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 74.2,
      "womenTimeSec": 80.7
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 159.0,
      "womenTimeSec": 181.5
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 72.2,
      "womenTimeSec": 76.8
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 163.5,
      "womenTimeSec": 183.0
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 349.5,
      "womenTimeSec": 394.0
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 29.8,
      "womenTimeSec": 33.3
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 67.7,
      "womenTimeSec": 72.7
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 149.5,
      "womenTimeSec": 160.5
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 317.0,
      "womenTimeSec": 347.0
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 50,
      "menTimeSec": 645.0,
      "womenTimeSec": 720.5
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 50,
      "menTimeSec": 1252.5,
      "womenTimeSec": 1420.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 36.3,
      "womenTimeSec": 40.3
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 80.2,
      "womenTimeSec": 92.2
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 177.5,
      "womenTimeSec": 195.5
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 32.8,
      "womenTimeSec": 35.8
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 71.4,
      "womenTimeSec": 83.2
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 162.0,
      "womenTimeSec": 184.5
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 33.8,
      "womenTimeSec": 35.8
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 75.2,
      "womenTimeSec": 82.2
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 162.0,
      "womenTimeSec": 185.0
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 166.0,
      "womenTimeSec": 185.5
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 353.5,
      "womenTimeSec": 397.5
    }
  ],
  "third_adult": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 32.3,
      "womenTimeSec": 35.5
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 74.2,
      "womenTimeSec": 81.2
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 166.5,
      "womenTimeSec": 174.5
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 361.0,
      "womenTimeSec": 388.5
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 25,
      "menTimeSec": 755.5,
      "womenTimeSec": 816.0
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 25,
      "menTimeSec": 1460.5,
      "womenTimeSec": 1694.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 40.3,
      "womenTimeSec": 43.3
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 89.2,
      "womenTimeSec": 101.2
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 193.0,
      "womenTimeSec": 212.5
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 36.3,
      "womenTimeSec": 38.3
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 82.2,
      "womenTimeSec": 92.2
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 184.0,
      "womenTimeSec": 205.0
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 35.8,
      "womenTimeSec": 38.3
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 83.2,
      "womenTimeSec": 88.7
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 184.0,
      "womenTimeSec": 207.0
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 79.2,
      "womenTimeSec": 84.7
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 180.0,
      "womenTimeSec": 203.5
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 396.5,
      "womenTimeSec": 434.0
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 34.3,
      "womenTimeSec": 37.3
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 75.7,
      "womenTimeSec": 82.7
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 168.5,
      "womenTimeSec": 177.5
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 368.0,
      "womenTimeSec": 392.5
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 50,
      "menTimeSec": 766.0,
      "womenTimeSec": 826.0
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 50,
      "menTimeSec": 1474.0,
      "womenTimeSec": 1702.5
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 41.3,
      "womenTimeSec": 44.3
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 90.7,
      "womenTimeSec": 102.2
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 194.5,
      "womenTimeSec": 214.5
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 36.8,
      "womenTimeSec": 38.8
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 82.7,
      "womenTimeSec": 93.2
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 184.5,
      "womenTimeSec": 207.5
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 36.8,
      "womenTimeSec": 38.3
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 84.7,
      "womenTimeSec": 90.2
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 186.5,
      "womenTimeSec": 209.0
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 182.5,
      "womenTimeSec": 204.5
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 398.0,
      "womenTimeSec": 440.0
    }
  ],
  "first_youth": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 38.8,
      "womenTimeSec": 41.8
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 38.8,
      "womenTimeSec": 41.8
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 86.7,
      "womenTimeSec": 93.7
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 86.7,
      "womenTimeSec": 93.7
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 190.5,
      "womenTimeSec": 204.5
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 190.5,
      "womenTimeSec": 204.5
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 51.8,
      "womenTimeSec": 57.8
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 51.8,
      "womenTimeSec": 57.8
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 109.7,
      "womenTimeSec": 123.7
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 109.7,
      "womenTimeSec": 123.7
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 229.5,
      "womenTimeSec": 255.5
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 229.5,
      "womenTimeSec": 255.5
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 44.8,
      "womenTimeSec": 50.8
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 44.8,
      "womenTimeSec": 50.8
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 94.7,
      "womenTimeSec": 109.7
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 94.7,
      "womenTimeSec": 109.7
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 214.5,
      "womenTimeSec": 231.5
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 214.5,
      "womenTimeSec": 231.5
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 44.8,
      "womenTimeSec": 49.8
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 44.8,
      "womenTimeSec": 49.8
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 94.7,
      "womenTimeSec": 105.7
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 94.7,
      "womenTimeSec": 105.7
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 212.5,
      "womenTimeSec": 227.5
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 212.5,
      "womenTimeSec": 227.5
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 99.7,
      "womenTimeSec": 107.7
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 99.7,
      "womenTimeSec": 107.7
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 215.5,
      "womenTimeSec": 230.5
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 215.5,
      "womenTimeSec": 230.5
    }
  ],
  "second_youth": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 45.8,
      "womenTimeSec": 48.8
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 45.8,
      "womenTimeSec": 48.8
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 103.5,
      "womenTimeSec": 113.5
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 103.5,
      "womenTimeSec": 113.5
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 195.0,
      "womenTimeSec": 246.0
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 195.0,
      "womenTimeSec": 246.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 55.8,
      "womenTimeSec": 63.8
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 55.8,
      "womenTimeSec": 63.8
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 123.5,
      "womenTimeSec": 136.5
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 123.5,
      "womenTimeSec": 136.5
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 265.0,
      "womenTimeSec": 292.0
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 265.0,
      "womenTimeSec": 292.0
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 50.8,
      "womenTimeSec": 55.8
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 50.8,
      "womenTimeSec": 55.8
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 109.5,
      "womenTimeSec": 121.5
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 109.5,
      "womenTimeSec": 121.5
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 237.0,
      "womenTimeSec": 262.0
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 237.0,
      "womenTimeSec": 262.0
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 50.8,
      "womenTimeSec": 58.8
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 50.8,
      "womenTimeSec": 58.8
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 116.5,
      "womenTimeSec": 128.5
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 116.5,
      "womenTimeSec": 128.5
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 251.0,
      "womenTimeSec": 276.0
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 251.0,
      "womenTimeSec": 276.0
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 116.7,
      "womenTimeSec": 124.7
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 116.7,
      "womenTimeSec": 124.7
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 245.0,
      "womenTimeSec": 271.0
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 245.0,
      "womenTimeSec": 271.0
    }
  ],
  "third_youth": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 49.46,
      "womenTimeSec": 52.7
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 49.46,
      "womenTimeSec": 52.7
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 111.78,
      "womenTimeSec": 122.58
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 111.78,
      "womenTimeSec": 122.58
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 210.6,
      "womenTimeSec": 265.68
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 210.6,
      "womenTimeSec": 265.68
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 60.26,
      "womenTimeSec": 68.9
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 60.26,
      "womenTimeSec": 68.9
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 133.38,
      "womenTimeSec": 147.42
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 133.38,
      "womenTimeSec": 147.42
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 286.2,
      "womenTimeSec": 315.36
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 286.2,
      "womenTimeSec": 315.36
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 54.86,
      "womenTimeSec": 60.26
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 54.86,
      "womenTimeSec": 60.26
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 118.26,
      "womenTimeSec": 131.22
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 118.26,
      "womenTimeSec": 131.22
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 255.96,
      "womenTimeSec": 282.96
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 255.96,
      "womenTimeSec": 282.96
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 54.86,
      "womenTimeSec": 63.5
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 54.86,
      "womenTimeSec": 63.5
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 125.82,
      "womenTimeSec": 138.78
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 125.82,
      "womenTimeSec": 138.78
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 271.08,
      "womenTimeSec": 298.08
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 271.08,
      "womenTimeSec": 298.08
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 126.04,
      "womenTimeSec": 134.68
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 126.04,
      "womenTimeSec": 134.68
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 264.6,
      "womenTimeSec": 292.68
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 264.6,
      "womenTimeSec": 292.68
    }
  ],
  "no_rank": [
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 37.14,
      "womenTimeSec": 40.82
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 85.33,
      "womenTimeSec": 93.38
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 191.47,
      "womenTimeSec": 200.67
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 415.15,
      "womenTimeSec": 446.77
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 25,
      "menTimeSec": 868.82,
      "womenTimeSec": 938.4
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 25,
      "menTimeSec": 1679.57,
      "womenTimeSec": 1948.1
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 46.34,
      "womenTimeSec": 49.79
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 102.58,
      "womenTimeSec": 116.38
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 221.95,
      "womenTimeSec": 244.37
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 41.74,
      "womenTimeSec": 44.04
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 94.53,
      "womenTimeSec": 106.03
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 211.6,
      "womenTimeSec": 235.75
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 25,
      "menTimeSec": 41.17,
      "womenTimeSec": 44.04
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 95.68,
      "womenTimeSec": 102.0
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 211.6,
      "womenTimeSec": 238.05
    },
    {
      "discipline": "im",
      "distanceMeters": 100,
      "poolLengthMeters": 25,
      "menTimeSec": 91.08,
      "womenTimeSec": 97.41
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 25,
      "menTimeSec": 207.0,
      "womenTimeSec": 234.02
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 25,
      "menTimeSec": 455.97,
      "womenTimeSec": 499.1
    },
    {
      "discipline": "free",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 39.44,
      "womenTimeSec": 42.89
    },
    {
      "discipline": "free",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 87.05,
      "womenTimeSec": 95.1
    },
    {
      "discipline": "free",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 193.77,
      "womenTimeSec": 204.12
    },
    {
      "discipline": "free",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 423.2,
      "womenTimeSec": 451.37
    },
    {
      "discipline": "free",
      "distanceMeters": 800,
      "poolLengthMeters": 50,
      "menTimeSec": 880.9,
      "womenTimeSec": 949.9
    },
    {
      "discipline": "free",
      "distanceMeters": 1500,
      "poolLengthMeters": 50,
      "menTimeSec": 1695.1,
      "womenTimeSec": 1957.87
    },
    {
      "discipline": "breast",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 47.49,
      "womenTimeSec": 50.94
    },
    {
      "discipline": "breast",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 104.3,
      "womenTimeSec": 117.53
    },
    {
      "discipline": "breast",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 223.67,
      "womenTimeSec": 246.67
    },
    {
      "discipline": "fly",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 42.32,
      "womenTimeSec": 44.62
    },
    {
      "discipline": "fly",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 95.1,
      "womenTimeSec": 107.18
    },
    {
      "discipline": "fly",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 212.17,
      "womenTimeSec": 238.62
    },
    {
      "discipline": "back",
      "distanceMeters": 50,
      "poolLengthMeters": 50,
      "menTimeSec": 42.32,
      "womenTimeSec": 44.04
    },
    {
      "discipline": "back",
      "distanceMeters": 100,
      "poolLengthMeters": 50,
      "menTimeSec": 97.41,
      "womenTimeSec": 103.73
    },
    {
      "discipline": "back",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 214.47,
      "womenTimeSec": 240.35
    },
    {
      "discipline": "im",
      "distanceMeters": 200,
      "poolLengthMeters": 50,
      "menTimeSec": 209.87,
      "womenTimeSec": 235.17
    },
    {
      "discipline": "im",
      "distanceMeters": 400,
      "poolLengthMeters": 50,
      "menTimeSec": 457.7,
      "womenTimeSec": 506.0
    }
  ]
};