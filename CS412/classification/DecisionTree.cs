using System;
using System.Collections.Generic;
using System.Linq;

class Solution
{
    static byte[,] trainingData, testData;
    static byte[] label;

    const int maxDepth = 5;

    class Node
    {
        public int attr;
        public Dictionary<byte, Node> children;

        public bool isLeaf = false;
        public byte leafVal;
    }

    static void Main(String[] args)
    {
        ReadTrainingData();
        Node decisionTree = TrainDecisionTree(Enumerable.Range(0, trainingData.GetLength(0)).ToList(), Enumerable.Range(0, trainingData.GetLength(1)).ToList(), 0);
        ReadTestData();
        byte[] classificationResults = Classify(decisionTree, testData);

        foreach (var item in classificationResults)
        {
            System.Console.WriteLine(item);
        }
    }

    private static Node TrainDecisionTree(List<int> relevantRows, List<int> attrs, int depth)
    {
        Node root = new Node();

        if (HasOnlyOneClass(relevantRows))
        {
            root.isLeaf = true;
            root.leafVal = label[relevantRows.First()];

            return root;
        }
        else if (attrs.Count == 0 || depth == maxDepth)
        {
            root.isLeaf = true;
            root.leafVal = FindMajorityClass(relevantRows);

            return root;
        }
        else
        {
            root.isLeaf = false;
            root.children = new Dictionary<byte, Node>();
        }

        root.attr = SelectSplitAttr(relevantRows, attrs);
        //System.Console.WriteLine($"Splitting on {root.attr}");
        List<int> remainingAttr = RemoveSelectedAttrFromList(attrs, root.attr);
        Dictionary<byte, List<int>> relevantRowsByPartition = GetRelevantRowsForEachPartition(root.attr, relevantRows);

        foreach (byte lbl in relevantRowsByPartition.Keys)
        {
            Node child = TrainDecisionTree(relevantRowsByPartition[lbl], remainingAttr, depth + 1);
            root.children.Add(lbl, child);
        }

        return root;
    }

    private static bool HasOnlyOneClass(List<int> rows)
    {
        int refIdx = rows.First();
        foreach (var idx in rows)
        {
            if (label[idx] != label[refIdx])
                return false;
        }

        return true;
    }

    private static List<int> RemoveSelectedAttrFromList(List<int> attributes, int attrToRemove)
    {
        var newList = new List<int>(attributes);
        newList.Remove(attrToRemove);
        return newList;
    }

    private static byte FindMajorityClass(List<int> relevantRows)
    {
        var counts = new Dictionary<byte, int>();
        foreach (var rowidx in relevantRows)
        {
            if (!counts.ContainsKey(label[rowidx]))
                counts.Add(label[rowidx], 1);
            else
                ++counts[label[rowidx]];
        }

        byte majClass = 0;
        int maxCount = -1;
        foreach (var key in counts.Keys)
        {
            if (counts[key] > maxCount)
            {
                maxCount = counts[key];
                majClass = key;
            }
        }

        return majClass;
    }

    private static Dictionary<byte, List<int>> GetRelevantRowsForEachPartition(int selectedAttr, List<int> rows)
    {
        var dict = new Dictionary<byte, List<int>>();
        foreach (int rowIdx in rows)
        {
            if (!dict.ContainsKey(trainingData[rowIdx, selectedAttr]))
                dict.Add(trainingData[rowIdx, selectedAttr], new List<int>());

            dict[trainingData[rowIdx, selectedAttr]].Add(rowIdx);
        }

        return dict;
    }

    private static int SelectSplitAttr(List<int> relevantRows, List<int> attrs)
    {
        var cntByAttrValAndLabel = new Dictionary<byte, Dictionary<byte, int>>();
        var attrValTotalCnt = new Dictionary<byte, int>();
        double minGini = double.MaxValue, currGini;
        int selectedAttr = -1;

        foreach (int attr in attrs)
        {
            cntByAttrValAndLabel.Clear();
            attrValTotalCnt.Clear();

            foreach (int idx in relevantRows)
            {
                if (!cntByAttrValAndLabel.ContainsKey(trainingData[idx, attr]))
                {
                    cntByAttrValAndLabel.Add(trainingData[idx, attr], new Dictionary<byte, int>());
                    cntByAttrValAndLabel[trainingData[idx, attr]].Add(label[idx], 1);
                    attrValTotalCnt.Add(trainingData[idx, attr], 1);
                }
                else
                {
                    var temp = cntByAttrValAndLabel[trainingData[idx, attr]];
                    if (temp.ContainsKey(label[idx]))
                        ++temp[label[idx]];
                    else
                        temp.Add(label[idx], 1);
                    ++attrValTotalCnt[trainingData[idx, attr]];
                }
            }

            currGini = 0;
            foreach (byte attrVal in cntByAttrValAndLabel.Keys)
            {
                double prob = 0.0d;
                foreach (byte labelVal in cntByAttrValAndLabel[attrVal].Keys)
                {
                    prob += Math.Pow((double)cntByAttrValAndLabel[attrVal][labelVal] / attrValTotalCnt[attrVal], 2.0);
                }

                currGini += (attrValTotalCnt[attrVal] / (double)relevantRows.Count) * (1 - prob);
            }

            if (currGini < minGini)
            {
                minGini = currGini;
                selectedAttr = attr;
            }
        }

        return selectedAttr;
    }

    private static byte[] Classify(Node decisionTree, byte[,] data)
    {
        var results = new byte[data.GetLength(0)];

        for (int i = 0; i < results.Length; i++)
        {
            Node currNode = decisionTree;
            while (!currNode.isLeaf)
            {
                byte selectedAttrVal = data[i, currNode.attr];
                currNode = currNode.children[selectedAttrVal];
                
            }

            results[i] = currNode.leafVal;
        }

        return results;
    }

    private static void ReadTrainingData()
    {
        int numberOfLines = int.Parse(Console.ReadLine());
        string[] line = Console.ReadLine().Split(' ');
        int numberOfAttrs = line.Length - 1;

        trainingData = new byte[numberOfLines, numberOfAttrs];
        label = new byte[numberOfLines];

        for (int i = 0; i < numberOfLines; i++)
        {
            label[i] = byte.Parse(line[0]);
            for (int j = 1; j < line.Length; j++)
            {
                byte val = byte.Parse(line[j].Split(':')[1]);
                trainingData[i, j - 1] = val;
            }
            if (i < numberOfLines - 1)
                line = Console.ReadLine().Split(' ');
        }
    }

    private static void ReadTestData()
    {
        int numberOfLines = int.Parse(Console.ReadLine());
        string[] line = Console.ReadLine().Split(' ');
        int numberOfAttrs = line.Length;

        testData = new byte[numberOfLines, numberOfAttrs];

        for (int i = 0; i < numberOfLines; i++)
        {
            for (int j = 0; j < line.Length; j++)
            {
                byte val = byte.Parse(line[j].Split(':')[1]);
                testData[i, j] = val;
            }
            if (i < numberOfLines - 1)
                line = Console.ReadLine().Split(' ');
        }
    }
}