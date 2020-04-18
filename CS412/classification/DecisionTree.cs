using System;
using System.Collections.Generic;
using System.IO;
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

        public void AddSubtree(int attrValue, Node subtree)
        {
            children.Add(attrValue, subtree);
        }
    }



    static void Main(String[] args)
    {
        ReadTrainingData();
        Node decisionTree = TrainDecisionTree(Enumerable.Range(0, trainingData.GetLength(0)), Enumerable.Range(0, trainingData.GetLength(1)), 0);
        ReadTestData();
    }

    private static Node TrainDecisionTree(List<int> relevantRows, List<int> attrs, int depth)
    {
        Node root = new Node();

        if(attrs.Count == 0 || depth == maxDepth)
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
        
        int selectedAttr = SelectSplitAttr(relevantRows, attrs);
        List<int> remainingAttr = RemoveSelectedAttrFromList(attrs, selectedAttr);
        Dictionary<byte, List<int>> relevantRowsByPartition = GetRelevantRowsForEachPartition(selectedAttr, relevantRows);

        foreach (byte lbl in relevantRowsByPartition.Keys)
        {
            Node child = TrainDecisionTree(relevantRowsByPartition[lbl], remainingAttr, depth+1);
            root.children.Add(lbl, child);
        }

        return root;
    }

    private static List<int> RemoveSelectedAttrFromList(List<int> attributes, int attrToRemove)
    {
        var newList = new List<int>(attributes);
        newList.Remove(attrToRemove);
        return newList;
    }

    private static byte FindMajorityClass(IEnumerable relevantRows){
        var counts = new Dictionary<byte, int>();
        foreach (var item in label)
        {
            if(counts.ContainsKey(item))
                ++counts[item];
            else
                counts.Add(item, 1);
        }

        byte majClass;
        int maxCount = -1;
        foreach (var key in counts.Keys)
        {
            if(counts[key] > maxCount)
            {
                maxCount = counts[key];
                majClass = key;
            }
        }

        return majClass;
    }

    private static Dictionary<byte, List<int>> GetRelevantRowsForEachPartition(int selectedAttr, IEnumerable rows)
    {
        var dict = new Dictionary<byte, List<int>>();
        foreach (int rowIdx in rows)
        {
            if(!dict.ContainsKey(trainingData[rowIdx, selectedAttr]))
                dict.Add(trainingData[rowIdx, selectedAttr], new List<int>());
            
            dict[trainingData[rowIdx, selectedAttr]].Add(rowIdx);
        }

        return dict;
    }

    private static int SelectSplitAttr(IEnumerable relevantRows, IEnumerable attrs)
    {
        var cntByAttrValAndLabel = new Dictionary<byte, Dictionary<byte, int>>();
        var labelTotalCount = new Dictionary<byte, int>();
        double minGini = double.MaxValue, currGini;
        int selectedAttr;

        foreach (int attr in attrs)
        {
            foreach (int idx in relevantRows)
            {
                if (!cntByAttrValAndLabel.ContainsKey(trainingData[idx, attr]))
                {
                    cntByAttrValAndLabel.Add(trainingData[idx, attr], new Dictionary<byte, int>());
                    cntByAttrValAndLabel[trainingData[idx, attr]].Add(label[idx], 1);
                    labelTotalCount.Add(trainingData[idx, attr], 1);
                }
                else
                {
                    ++cntByAttrValAndLabel[trainingData[idx, attr]][label[idx]];
                    ++labelTotalCount(trainingData[idx, attr]);
                }
            }

            foreach (byte attrVal in cntByAttrValAndLabel.Keys)
            {
                double prob = 0.0d;
                foreach (byte labelVal in cntByAttrValAndLabel[attrVal])
                {
                    prob += Math.Pow((double)cntByAttrValAndLabel[attrVal][labelVal] / labelTotalCount[attrVal], 2.0);
                }

                currGini = (labelTotalCount[attrVal]/(double)relevantRows.Length) * (1 - prob);
                if(currGini < minGini)
                {
                    minGini = currGini;
                    selectedAttr = attr;
                }
            }
        }

        return selectedAttr;
    }

    private static void ReadTrainingData()
    {
        int numberOfLines = int.Parse(Console.ReadLine());
        string[] line = Console.ReadLine().Split(" ");
        int numberOfAttrs = line.Length - 1;

        trainingData = new byte[numberOfLines, numberOfAttrs];
        label = new byte[numberOfLines];

        for (int i = 1; i < numberOfLines; i++)
        {
            label[i] = byte.Parse(line[0]);
            for (int j = 1; j < line.Length; j++)
            {
                byte val = byte.Parse(line[j].Split(":")[1]);
                trainingData[i, j - 1] = val;
            }
            line = Console.ReadLine().Split(" ");
        }
    }

    private static void ReadTestData()
    {
        int numberOfLines = int.Parse(Console.ReadLine());
        string[] line = Console.ReadLine().Split(" ");
        int numberOfAttrs = line.Length;

        var data = new byte[numberOfLines, numberOfAttrs];

        for (int i = 1; i < numberOfLines; i++)
        {
            for (int j = 0; j < line.Length; j++)
            {
                byte val = byte.Parse(line[j].Split(":")[1]);
                testData[i, j] = val;
            }
            line = Console.ReadLine().Split(" ");
        }
    }
}