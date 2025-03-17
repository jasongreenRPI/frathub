const express = require('express');
const Queue = require('../database/Schemas/queue');
const Organization = require('../database/Schemas/organization');
const { authenticateToken, authorizeRole } = require('../middleware/auth.middleware');
const router = express.Router();

// Get queue status for an organization
router.get('/org/:orgId', authenticateToken, async (req, res) => {
  try {
    const { orgId } = req.params;
    
    // Verify organization exists
    const organization = await Organization.findById(orgId);
    if (!organization) {
      return res.status(404).json({
        success: false,
        message: 'Organization not found'
      });
    }
    
    // Check if user has permission to view the queue (member, officer, or superuser)
    if (
      req.user.role !== 'superuser' && 
      organization.superUserId.toString() !== req.user.userId &&
      !organization.memberIds.includes(req.user.userId) &&
      !organization.officerIds.includes(req.user.userId)
    ) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You do not have permission to view this queue.'
      });
    }
    
    // Find queue for the organization
    let queue = await Queue.findOne({ orgId });
    
    // If queue doesn't exist, create a new one
    if (!queue) {
      queue = new Queue({ orgId });
      await queue.save();
    }
    
    res.status(200).json({
      success: true,
      data: queue
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Update queue status (officer or superuser only)
router.patch('/org/:orgId', authenticateToken, async (req, res) => {
  try {
    const { orgId } = req.params;
    const { status, openToOutside } = req.body;
    
    // Verify organization exists
    const organization = await Organization.findById(orgId);
    if (!organization) {
      return res.status(404).json({
        success: false,
        message: 'Organization not found'
      });
    }
    
    // Check if user has permission to update the queue (officer or superuser)
    if (
      req.user.role !== 'superuser' && 
      organization.superUserId.toString() !== req.user.userId &&
      !organization.officerIds.includes(req.user.userId)
    ) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only officers can update queue settings.'
      });
    }
    
    // Find queue for the organization
    let queue = await Queue.findOne({ orgId });
    
    // If queue doesn't exist, create a new one
    if (!queue) {
      queue = new Queue({ orgId });
    }
    
    // Update queue settings
    if (status !== undefined) {
      queue.status = status;
    }
    
    if (openToOutside !== undefined) {
      queue.openToOutside = openToOutside;
    }
    
    await queue.save();
    
    res.status(200).json({
      success: true,
      data: queue
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Get all queues (admin only)
router.get('/', authenticateToken, authorizeRole(['superuser']), async (req, res) => {
  try {
    const queues = await Queue.find().populate('orgId', 'name');
    
    res.status(200).json({
      success: true,
      count: queues.length,
      data: queues
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;