# psl-weightlearning-experiments
This repository runs experiments to test the performance improvement due to weight learning on PSL.

### Requirements
* python3 
* git
* wget 

### Repository structure 
```
+-- psl-examples (cloned from github by runAllWl.sh script)
├── knowledge-graph-identification
│   ├── README.md
│   ├── cli
│   │   ├── knowledge-graph-identification-eval.data
│   │   ├── knowledge-graph-identification-learn.data
│   │   ├── knowledge-graph-identification.psl
│   │   └── run.sh
│   ├── data
│   │   └── fetchData.sh
│   ├── groovy
│   │   ├── bin
│   │   │   ├── pom.xml
│   │   │   ├── run.sh
│   │   │   ├── src
│   │   │   │   └── main
│   │   │   │       ├── java
│   │   │   │       │   └── org
│   │   │   │       │       └── linqs
│   │   │   │       │           └── psl
│   │   │   │       │               └── examples
│   │   │   │       │                   └── kgi
│   │   │   │       │                       └── Run.groovy
│   │   │   │       └── resources
│   │   │   │           ├── log4j.properties
│   │   │   │           └── psl.properties
│   │   │   └── target
│   │   │       └── classes
│   │   │           ├── log4j.properties
│   │   │           └── psl.properties
│   │   ├── pom.xml
│   │   ├── run.sh
│   │   ├── src
│   │   │   └── main
│   │   │       ├── java
│   │   │       │   └── org
│   │   │       │       └── linqs
│   │   │       │           └── psl
│   │   │       │               └── examples
│   │   │       │                   └── kgi
│   │   │       │                       └── Run.groovy
│   │   │       └── resources
│   │   │           ├── log4j.properties
│   │   │           └── psl.properties
│   │   └── target
│   │       └── classes
│   │           ├── log4j.properties
│   │           └── psl.properties
│   └── python
│       ├── knowledge-graph-identification.py
│       └── run.sh
|	...
|	...
.
├── README.md
├── other-examples
│   ├── lastfm
│   │   ├── data
│   │   │   ├── README.md
│   │   │   └── fetchData.sh
│   │   └── psl-cli
│   │       ├── lastfm-eval.data
│   │       ├── lastfm-learn.data
│   │       ├── lastfm-template.data
│   │       └── lastfm.psl
│   └── yelp
│       ├── data
│       │   ├── README.md
│       │   └── fetchData.sh
│       └── psl-cli
│           ├── yelp-template.data
│           └── yelp.psl
└── runAllWL.sh
```

