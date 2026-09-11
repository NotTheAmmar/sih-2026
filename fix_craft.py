import re

with open('lib/models/craft_attributes.dart', 'r') as f:
    text = f.read()

# Replace block 1 (constructor)
text = re.sub(
    r'<<<<<<< HEAD\n    this\.dimensions,\n=======\n(.*?)\n>>>>>>> origin/main',
    r'    this.dimensions,\n\1',
    text,
    flags=re.DOTALL
)

# Replace block 2 (copyWith param)
text = re.sub(
    r'<<<<<<< HEAD\n    String\? dimensions,\n=======\n(.*?)\n>>>>>>> origin/main',
    r'    String? dimensions,\n\1',
    text,
    flags=re.DOTALL
)

# Replace block 3 (copyWith usage)
text = re.sub(
    r'<<<<<<< HEAD\n      dimensions: dimensions \?\? this\.dimensions,\n=======\n(.*?)\n>>>>>>> origin/main',
    r'      dimensions: dimensions ?? this.dimensions,\n\1',
    text,
    flags=re.DOTALL
)

# Replace block 4 (toJson)
text = re.sub(
    r'<<<<<<< HEAD\n        \'dimensions\': dimensions,\n=======\n(.*?)\n>>>>>>> origin/main',
    r'        \'dimensions\': dimensions,\n\1',
    text,
    flags=re.DOTALL
)

# Replace block 5 (fromJson)
text = re.sub(
    r'<<<<<<< HEAD\n        dimensions: json\[\'dimensions\'\] as String\?,\n=======\n(.*?)\n>>>>>>> origin/main',
    r'        dimensions: json[\'dimensions\'] as String?,\n\1',
    text,
    flags=re.DOTALL
)

with open('lib/models/craft_attributes.dart', 'w') as f:
    f.write(text)

