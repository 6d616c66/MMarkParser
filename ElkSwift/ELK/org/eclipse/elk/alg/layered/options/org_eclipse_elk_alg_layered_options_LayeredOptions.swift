// Ported from elk-source/plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/Layered.melk
import Foundation

internal final class org_eclipse_elk_alg_layered_options_LayeredOptions {

    // Algorithm identifier
    internal static let ALGORITHM_ID = "org.eclipse.elk.layered"

    // p1/p2 + reverse blocker option keys
    internal static let LAYERING_LAYER_CONSTRAINT = Property<Any>("org.eclipse.elk.layered.layering.layerConstraint")
    internal static let EDGE_LABELS_PLACEMENT = Property<Any>("org.eclipse.elk.edgeLabels.placement")
    internal static let NODE_LABELS_PLACEMENT = Property<Any>("org.eclipse.elk.nodeLabels.placement")
    internal static let PORT_CONSTRAINTS = Property<Any>("org.eclipse.elk.portConstraints")
    internal static let THOROUGHNESS = Property<Int>("org.eclipse.elk.layered.thoroughness")

    // Spacing options (defaults from ELK CoreOptions / LayeredMetaDataProvider)
    internal static let SPACING_EDGE_EDGE = Property<Double>("org.eclipse.elk.spacing.edgeEdge", 10.0)
    internal static let SPACING_NODE_NODE = Property<Double>("org.eclipse.elk.spacing.nodeNode", 20.0)
    internal static let SPACING_PORT_PORT = Property<Double>("org.eclipse.elk.spacing.portPort", 10.0)
    internal static let SPACING_PORTS_SURROUNDING = Property<Any>("org.eclipse.elk.spacing.portsSurrounding")
    internal static let SPACING_EDGE_NODE = Property<Double>("org.eclipse.elk.spacing.edgeNode", 10.0)
    internal static let SPACING_EDGE_LABEL = Property<Double>("org.eclipse.elk.spacing.edgeLabel", 2.0)
    internal static let SPACING_LABEL_LABEL = Property<Double>("org.eclipse.elk.spacing.labelLabel", 0.0)
    internal static let SPACING_LABEL_PORT = Property<Double>("org.eclipse.elk.spacing.labelPort", 5.0)
    internal static let SPACING_LABEL_NODE = Property<Double>("org.eclipse.elk.spacing.labelNode", 5.0)
    internal static let SPACING_LABEL_PORT_HORIZONTAL = Property<Double>("org.eclipse.elk.spacing.labelPortHorizontal", 1.0)
    internal static let SPACING_LABEL_PORT_VERTICAL = Property<Double>("org.eclipse.elk.spacing.labelPortVertical", 1.0)
    internal static let SPACING_EDGE_EDGE_BETWEEN_LAYERS = Property<Double>("org.eclipse.elk.layered.spacing.edgeEdgeBetweenLayers", 10.0)
    internal static let SPACING_EDGE_NODE_BETWEEN_LAYERS = Property<Double>("org.eclipse.elk.layered.spacing.edgeNodeBetweenLayers", 10.0)
    internal static let SPACING_NODE_NODE_BETWEEN_LAYERS = Property<Double>("org.eclipse.elk.layered.spacing.nodeNodeBetweenLayers", 20.0)
    internal static let SPACING_COMMENT_COMMENT = Property<Double>("org.eclipse.elk.spacing.commentComment", 10.0)
    internal static let SPACING_COMMENT_NODE = Property<Double>("org.eclipse.elk.spacing.commentNode", 10.0)
    internal static let SPACING_COMPONENT_COMPONENT = Property<Double>("org.eclipse.elk.spacing.componentComponent", 20.0)
    internal static let SPACING_BASE_VALUE = Property<Double>("org.eclipse.elk.spacing.baseValue", 0.0)

    // Priority options
    internal static let PRIORITY = Property<Int>("org.eclipse.elk.priority")
    internal static let PRIORITY_DIRECTION = Property<Int>("org.eclipse.elk.layered.priority.direction")
    internal static let PRIORITY_SHORTNESS = Property<Int>("org.eclipse.elk.layered.priority.shortness")
    internal static let PRIORITY_STRAIGHTNESS = Property<Int>("org.eclipse.elk.layered.priority.straightness")

    internal static let INTERACTIVE_REFERENCE_POINT = Property<Any>("org.eclipse.elk.layered.interactiveReferencePoint")

    // Node placement options
    internal static let NODE_PLACEMENT_FAVOR_STRAIGHT_EDGES = Property<Bool>("org.eclipse.elk.layered.nodePlacement.favorStraightEdges")
    internal static let NODE_PLACEMENT_BK_EDGE_STRAIGHTENING = Property<Any>("org.eclipse.elk.layered.nodePlacement.bk.edgeStraightening")
    internal static let NODE_PLACEMENT_BK_FIXED_ALIGNMENT = Property<Any>("org.eclipse.elk.layered.nodePlacement.bk.fixedAlignment")
    internal static let NODE_PLACEMENT_LINEAR_SEGMENTS_DEFLECTION_DAMPENING = Property<Double>("org.eclipse.elk.layered.nodePlacement.linearSegments.deflectionDampening")
    internal static let NODE_PLACEMENT_STRATEGY = Property<Any>("org.eclipse.elk.layered.nodePlacement.strategy")

    // Model-order group options
    internal static let CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_CYCLE_BREAKING_ID = Property<Any>("org.eclipse.elk.layered.considerModelOrder.groupModelOrder.cycleBreakingId")
    internal static let CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_CROSSING_MINIMIZATION_ID = Property<Any>("org.eclipse.elk.layered.considerModelOrder.groupModelOrder.crossingMinimizationId")
    internal static let CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_COMPONENT_GROUP_ID = Property<Any>("org.eclipse.elk.layered.considerModelOrder.groupModelOrder.componentGroupId")
    internal static let CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_CB_GROUP_ORDER_STRATEGY = Property<Any>("org.eclipse.elk.layered.considerModelOrder.groupModelOrder.cbGroupOrderStrategy")
    internal static let CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_CM_GROUP_ORDER_STRATEGY = Property<Any>("org.eclipse.elk.layered.considerModelOrder.groupModelOrder.cmGroupOrderStrategy")
    internal static let CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_CM_ENFORCED_GROUP_ORDERS = Property<Any>("org.eclipse.elk.layered.considerModelOrder.groupModelOrder.cmEnforcedGroupOrders")
    internal static let CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_CB_PREFERRED_SOURCE_ID = Property<Any>("org.eclipse.elk.layered.considerModelOrder.groupModelOrder.cbPreferredSourceId")
    internal static let CONSIDER_MODEL_ORDER_GROUP_MODEL_ORDER_CB_PREFERRED_TARGET_ID = Property<Any>("org.eclipse.elk.layered.considerModelOrder.groupModelOrder.cbPreferredTargetId")

    // Core options delegated from CoreOptions
    internal static let DIRECTION = Property<Direction>("org.eclipse.elk.direction")
    internal static let LAYERING_LAYER_ID = Property<Int>("org.eclipse.elk.layered.layering.layerId")
    internal static let CROSSING_MINIMIZATION_IN_LAYER_PRED_OF = Property<Any>("org.eclipse.elk.layered.crossingMinimization.inLayerPredOf")
    internal static let CROSSING_MINIMIZATION_IN_LAYER_SUCC_OF = Property<Any>("org.eclipse.elk.layered.crossingMinimization.inLayerSuccOf")

    // Core options
    internal static let NODE_SIZE_CONSTRAINTS = Property<Any>("org.eclipse.elk.nodeSize.constraints")
    internal static let NODE_SIZE_OPTIONS = Property<Any>("org.eclipse.elk.nodeSize.options")
    internal static let NODE_SIZE_MINIMUM = Property<Any>("org.eclipse.elk.nodeSize.minimum")
    internal static let NODE_SIZE_FIXED_GRAPH_SIZE = Property<Bool>("org.eclipse.elk.nodeSize.fixedGraphSize")
    internal static let NO_LAYOUT = Property<Bool>("org.eclipse.elk.noLayout")
    internal static let LAYERING_LAYER_CHOICE_CONSTRAINT = Property<Int>("org.eclipse.elk.layered.layering.layerChoiceConstraint")
    internal static let PORT_LABELS_PLACEMENT = Property<Any>("org.eclipse.elk.portLabels.placement")
    internal static let PORT_LABELS_NEXT_TO_PORT_IF_POSSIBLE = Property<Bool>("org.eclipse.elk.portLabels.nextToPortIfPossible")
    internal static let PORT_ALIGNMENT_DEFAULT = Property<Any>("org.eclipse.elk.portAlignment.default")
    internal static let PORT_SIDE = Property<Any>("org.eclipse.elk.port.side")
    internal static let PORT_BORDER_OFFSET = Property<Double>("org.eclipse.elk.port.borderOffset")
    internal static let PORT_ANCHOR = Property<KVector>("org.eclipse.elk.port.anchor")
    internal static let PORT_INDEX = Property<Int>("org.eclipse.elk.port.index")
    internal static let PADDING = Property<Any>("org.eclipse.elk.padding")
    internal static let ALIGNMENT = Property<Any>("org.eclipse.elk.alignment")
    internal static let NODE_LABELS_PADDING = Property<Any>("org.eclipse.elk.nodeLabels.padding")
    internal static let ASPECT_RATIO = Property<Double>("org.eclipse.elk.aspectRatio")
    internal static let POSITION = Property<Any>("org.eclipse.elk.position")
    internal static let DESIRED_POSITION = Property<Any>("org.eclipse.elk.position")
    internal static let INSIDE_SELF_LOOPS_ACTIVATE = Property<Bool>("org.eclipse.elk.insideSelfLoops.activate")
    internal static let INSIDE_SELF_LOOPS_YO = Property<Bool>("org.eclipse.elk.insideSelfLoops.yo")
    internal static let SEPARATE_CONNECTED_COMPONENTS = Property<Bool>("org.eclipse.elk.separateConnectedComponents")
    internal static let CONTENT_ALIGNMENT = Property<Any>("org.eclipse.elk.contentAlignment")
    internal static let EDGE_ROUTING = Property<Any>("org.eclipse.elk.edgeRouting")
    internal static let EDGE_ROUTING_SPLINES_MODE = Property<Any>("org.eclipse.elk.edgeRouting.splines.mode")
    internal static let EDGE_ROUTING_SELF_LOOP_DISTRIBUTION = Property<SelfLoopDistributionStrategy>("org.eclipse.elk.layered.edgeRouting.selfLoopDistribution", SelfLoopDistributionStrategy.NORTH)
    internal static let EDGE_ROUTING_SELF_LOOP_ORDERING = Property<SelfLoopOrderingStrategy>("org.eclipse.elk.layered.edgeRouting.selfLoopOrdering", SelfLoopOrderingStrategy.STACKED)
    internal static let SPACING_NODE_SELF_LOOP = Property<Double>("org.eclipse.elk.layered.spacing.nodeSelfLoop", 10.0)
    internal static let EDGE_ROUTING_POLYLINE_SLOPED_EDGE_ZONE_WIDTH = Property<Double>("org.eclipse.elk.layered.edgeRouting.polyline.slopedEdgeZoneWidth")
    internal static let EDGE_THICKNESS = Property<Double>("org.eclipse.elk.edge.thickness", 1.0)
    internal static let JUNCTION_POINTS = Property<KVectorChain>("org.eclipse.elk.junctionPoints")
    internal static let COMMENT_BOX = Property<Bool>("org.eclipse.elk.commentBox")
    internal static let HYPERNODE = Property<Bool>("org.eclipse.elk.hypernode")
    internal static let HIERARCHY_HANDLING = Property<Any>("org.eclipse.elk.hierarchyHandling")
    internal static let INTERACTIVE_LAYOUT = Property<Bool>("org.eclipse.elk.interactive")
    internal static let EDGE_LABELS_SIDE_SELECTION = Property<Any>("org.eclipse.elk.layered.edgeLabels.sideSelection")
    internal static let EDGE_LABELS_INLINE = Property<Bool>("org.eclipse.elk.edgeLabels.inline")
    internal static let UNNECESSARY_BENDPOINTS = Property<Bool>("org.eclipse.elk.layered.unnecessaryBendpoints")
    internal static let DIRECTION_CONGRUENCY = Property<Any>("org.eclipse.elk.layered.directionCongruency")
    internal static let FEEDBACK_EDGES = Property<Bool>("org.eclipse.elk.layered.feedbackEdges")
    internal static let MERGE_EDGES = Property<Bool>("org.eclipse.elk.layered.mergeEdges")
    internal static let MERGE_HIERARCHY_EDGES = Property<Bool>("org.eclipse.elk.layered.mergeHierarchyEdges")
    internal static let RANDOM_SEED = Property<Int>("org.eclipse.elk.randomSeed")
    internal static let MIN_WIDTH = Property<Double>("org.eclipse.elk.layered.minWidth")
    internal static let MIN_HEIGHT = Property<Double>("org.eclipse.elk.layered.minHeight")

    // Crossing minimization options
    internal static let CROSSING_MINIMIZATION_STRATEGY = Property<Any>("org.eclipse.elk.layered.crossingMinimization.strategy")
    internal static let CROSSING_MINIMIZATION_GREEDY_SWITCH_ACTIVATION_THRESHOLD = Property<Int>("org.eclipse.elk.layered.crossingMinimization.greedySwitchActivationThreshold")
    internal static let CROSSING_MINIMIZATION_GREEDY_SWITCH_TYPE = Property<Any>("org.eclipse.elk.layered.crossingMinimization.greedySwitchType")
    internal static let CROSSING_MINIMIZATION_GREEDY_SWITCH_HIERARCHICAL_TYPE = Property<Any>("org.eclipse.elk.layered.crossingMinimization.greedySwitchHierarchicalType")
    internal static let CROSSING_MINIMIZATION_SEMI_INTERACTIVE = Property<Bool>("org.eclipse.elk.layered.crossingMinimization.semiInteractive")
    internal static let CROSSING_MINIMIZATION_FORCE_NODE_MODEL_ORDER = Property<Bool>("org.eclipse.elk.layered.crossingMinimization.forceNodeModelOrder")
    internal static let CROSSING_MINIMIZATION_HIERARCHICAL_SWEEPINESS = Property<Double>("org.eclipse.elk.layered.crossingMinimization.hierarchicalSweepiness")
    internal static let CROSSING_MINIMIZATION_POSITION_CHOICE_CONSTRAINT = Property<Int>("org.eclipse.elk.layered.crossingMinimization.positionChoiceConstraint")
    internal static let CROSSING_MINIMIZATION_POSITION_ID = Property<Int>("org.eclipse.elk.layered.crossingMinimization.positionId")

    // Model order options
    internal static let CONSIDER_MODEL_ORDER_STRATEGY = Property<Any>("org.eclipse.elk.layered.considerModelOrder.strategy")
    internal static let CONSIDER_MODEL_ORDER_CROSSING_COUNTER_NODE_INFLUENCE = Property<Double>("org.eclipse.elk.layered.considerModelOrder.crossingCounterNodeInfluence")
    internal static let CONSIDER_MODEL_ORDER_CROSSING_COUNTER_PORT_INFLUENCE = Property<Double>("org.eclipse.elk.layered.considerModelOrder.crossingCounterPortInfluence")
    internal static let CONSIDER_MODEL_ORDER_NO_MODEL_ORDER = Property<Bool>("org.eclipse.elk.layered.considerModelOrder.noModelOrder")
    internal static let CONSIDER_MODEL_ORDER_COMPONENTS = Property<Any>("org.eclipse.elk.layered.considerModelOrder.components")
    internal static let CONSIDER_MODEL_ORDER_LONG_EDGE_STRATEGY = Property<Any>("org.eclipse.elk.layered.considerModelOrder.longEdgeStrategy")

    // Layering options
    internal static let LAYERING_STRATEGY = Property<Any>("org.eclipse.elk.layered.layering.strategy")
    internal static let LAYERING_NODE_PROMOTION_STRATEGY = Property<Any>("org.eclipse.elk.layered.layering.nodePromotion.strategy")
    internal static let LAYERING_COFFMAN_GRAHAM_LAYER_BOUND = Property<Int>("org.eclipse.elk.layered.layering.coffmanGraham.layerBound")
    internal static let LAYER_UNZIPPING_STRATEGY = Property<Any>("org.eclipse.elk.layered.layerUnzippingStrategy")

    // Cycle breaking
    internal static let CYCLE_BREAKING_STRATEGY = Property<Any>("org.eclipse.elk.layered.cycleBreaking.strategy")

    // Allow non-flow ports to switch sides (default false)
    internal static let ALLOW_NON_FLOW_PORTS_TO_SWITCH_SIDES = Property<Bool>("org.eclipse.elk.layered.allowNonFlowPortsToSwitchSides")

    // Compaction options
    internal static let COMPACTION_POST_COMPACTION_STRATEGY = Property<Any>("org.eclipse.elk.layered.compaction.postCompaction.strategy")
    internal static let COMPACTION_POST_COMPACTION_CONSTRAINTS = Property<Any>("org.eclipse.elk.layered.compaction.postCompaction.constraints")
    internal static let COMPACTION_CONNECTED_COMPONENTS = Property<Bool>("org.eclipse.elk.layered.compaction.connectedComponents")

    // High degree node options
    internal static let HIGH_DEGREE_NODES_TREATMENT = Property<Bool>("org.eclipse.elk.layered.highDegreeNodes.treatment")
    internal static let HIGH_DEGREE_NODES_THRESHOLD = Property<Int>("org.eclipse.elk.layered.highDegreeNodes.threshold")
    internal static let HIGH_DEGREE_NODES_TREE_HEIGHT = Property<Int>("org.eclipse.elk.layered.highDegreeNodes.treeHeight")

    // Partitioning
    internal static let PARTITIONING_ACTIVATE = Property<Bool>("org.eclipse.elk.partitioning.activate")

    // Generate IDs
    internal static let GENERATE_POSITION_AND_LAYER_IDS = Property<Bool>("org.eclipse.elk.layered.generatePositionAndLayerIds")
    internal static let PORT_SORTING_STRATEGY = Property<Any>("org.eclipse.elk.layered.portSortingStrategy")
    internal static let EDGE_LABELS_CENTER_LABEL_PLACEMENT_STRATEGY = Property<Any>("org.eclipse.elk.layered.edgeLabels.centerLabelPlacementStrategy")

    // Wrapping options
    internal static let WRAPPING_STRATEGY = Property<Any>("org.eclipse.elk.layered.wrapping.strategy")
    internal static let WRAPPING_ADDITIONAL_EDGE_SPACING = Property<Double>("org.eclipse.elk.layered.wrapping.additionalEdgeSpacing")
    internal static let WRAPPING_CORRECTION_FACTOR = Property<Double>("org.eclipse.elk.layered.wrapping.correctionFactor")
    internal static let WRAPPING_CUTTING_STRATEGY = Property<Any>("org.eclipse.elk.layered.wrapping.cutting.strategy")
    internal static let WRAPPING_CUTTING_CUTS = Property<Any>("org.eclipse.elk.layered.wrapping.cutting.cuts")
    internal static let WRAPPING_CUTTING_CUTS_MSD_FREEDOM = Property<Int>("org.eclipse.elk.layered.wrapping.cutting.msd.freedom")
    internal static let WRAPPING_VALIDIFY_STRATEGY = Property<Any>("org.eclipse.elk.layered.wrapping.validify.strategy")
    internal static let WRAPPING_VALIDIFY_FORBID_SELF_CROSSING_REDUCE_COUNTER = Property<Int>("org.eclipse.elk.layered.wrapping.validify.forbiddenIndices")
    internal static let WRAPPING_MULTI_EDGE_IMPROVE_CUTS = Property<Bool>("org.eclipse.elk.layered.wrapping.multiEdge.improveCuts")
    internal static let WRAPPING_MULTI_EDGE_IMPROVE_WRAPPED_EDGES = Property<Bool>("org.eclipse.elk.layered.wrapping.multiEdge.improveWrappedEdges")
    internal static let WRAPPING_MULTI_EDGE_DISTANCE_PENALTY = Property<Double>("org.eclipse.elk.layered.wrapping.multiEdge.distancePenalty")

    internal init() {}
}
