
typedef struct {
    int LengthInBytes;
    int StartingOffset;
    int values[3];
} ATTRIBUTES;

typedef struct {
    ATTRIBUTES Ranges[2];
} ATTRIBUTES_RANGES;

typedef struct {
    int a;
} X;
typedef struct {
    X x;
} Y;
typedef struct {
    Y y;
} Z;

void main() {
    ATTRIBUTES_RANGES attributeRanges;
    ATTRIBUTES Ranges[2] = attributeRanges.Ranges;
    ATTRIBUTES range0    = attributeRanges.Ranges[0];

    range0.StartingOffset = 0;
    range0.LengthInBytes  = 0;

    int Idx = 1;
    Ranges[Idx].StartingOffset = 3;
    Ranges[Idx].LengthInBytes  = 4;

    attributeRanges.Ranges[Idx].StartingOffset = 5;
    attributeRanges.Ranges[Idx].LengthInBytes  = 6;

    attributeRanges.Ranges[Idx].values[1] = 2;

    ATTRIBUTES_RANGES attributeRanges2[10];

    attributeRanges2[0].Ranges[1].values[2] = 0;

    Z z;
    z.y.x.a = 3;

    int a = z.y.x.a++;
    int b = ++z.y.x.a;
}
